// stock_service.nc — NeuralEdge Stock Intelligence Backend
// Written in NC Language. Run with: nc serve backend/stock_service.nc
//
// API surface expected by stock_dashboard.html:
//   POST /api/v1/portfolio/analyze   — add a stock position and get analysis
//   POST /api/v1/alerts/create       — create a price alert
//   GET  /api/v1/stocks              — list all tracked stocks with AI signals
//   GET  /api/v1/portfolio           — get all portfolio positions
//   GET  /api/v1/alerts              — get all active alerts
//   GET  /health                     — health check
//
// Copyright (c) 2025-2026 Nuckala Sai Narender / DevHeal Labs
// Licensed under Apache 2.0

service "neuraledge-stock"
version "1.0.0"

configure:
    port is 8000
    max_portfolio_size is 50
    max_alerts is 100

middleware:
    cors
    log_requests
    rate_limit 100 per minute

// ── In-memory data stores ─────────────────────────────────────────
set portfolio to []
set alerts to []
set next_id to 1

// ── Static market data (demo prices — replace with live feed) ─────
set market_data to [
    {symbol: "AAPL",  name: "Apple Inc.",             price: 189.42, change: 4.42,  change_pct: 2.38,  signal: "Strong Buy",  confidence: 0.87},
    {symbol: "MSFT",  name: "Microsoft Corp.",         price: 421.17, change: 7.43,  change_pct: 1.80,  signal: "Buy",         confidence: 0.79},
    {symbol: "GOOGL", name: "Alphabet Inc.",           price: 175.23, change: -1.06, change_pct: -0.60, signal: "Hold",        confidence: 0.61},
    {symbol: "NVDA",  name: "NVIDIA Corp.",            price: 875.64, change: 35.43, change_pct: 4.22,  signal: "Strong Buy",  confidence: 0.92},
    {symbol: "META",  name: "Meta Platforms Inc.",     price: 498.20, change: 14.98, change_pct: 3.10,  signal: "Buy",         confidence: 0.76},
    {symbol: "TSLA",  name: "Tesla Inc.",              price: 198.50, change: -4.29, change_pct: -2.12, signal: "Sell",        confidence: 0.68},
    {symbol: "AMZN",  name: "Amazon.com Inc.",         price: 184.30, change: 2.18,  change_pct: 1.20,  signal: "Buy",         confidence: 0.74},
    {symbol: "NFLX",  name: "Netflix Inc.",            price: 627.80, change: 5.60,  change_pct: 0.90,  signal: "Hold",        confidence: 0.58},
    {symbol: "AMD",   name: "Advanced Micro Devices",  price: 172.45, change: 8.22,  change_pct: 5.01,  signal: "Strong Buy",  confidence: 0.83},
    {symbol: "INTC",  name: "Intel Corp.",             price: 31.18,  change: -0.44, change_pct: -1.39, signal: "Sell",        confidence: 0.71},
    {symbol: "ORCL",  name: "Oracle Corp.",            price: 142.67, change: 2.11,  change_pct: 1.50,  signal: "Buy",         confidence: 0.72},
    {symbol: "CRM",   name: "Salesforce Inc.",         price: 298.44, change: 3.92,  change_pct: 1.33,  signal: "Hold",        confidence: 0.55}
]

// ── Helper: find stock by symbol ─────────────────────────────────
to find_stock with symbol:
    purpose: "Look up stock data by ticker symbol (case-insensitive)"
    set upper_sym to upper(symbol)
    repeat for each stock in market_data:
        if stock.symbol is equal upper_sym:
            respond with stock
    respond with nil

// ── Helper: generate a simple sequential ID ───────────────────────
to make_id:
    purpose: "Generate a unique sequential ID string"
    set id to "pos-" + string(next_id)
    set next_id to next_id + 1
    respond with id

// ── POST /api/v1/portfolio/analyze ────────────────────────────────
to analyze_portfolio with request:
    purpose: "Add a stock position to the portfolio and return analysis with AI signal"

    set symbol to request.stock_symbol_e_g_aapl
    set shares to request.number_of_shares
    set purchase_price to request.purchase_price

    // Validate inputs
    if symbol is empty:
        respond with {success: false, error: "Stock symbol is required"}
    if shares is empty:
        respond with {success: false, error: "Number of shares is required"}
    if shares is below 1:
        respond with {success: false, error: "Number of shares must be at least 1"}
    if purchase_price is empty:
        respond with {success: false, error: "Purchase price is required"}
    if purchase_price is below 0:
        respond with {success: false, error: "Purchase price must be a positive number"}
    if len(portfolio) is above max_portfolio_size:
        respond with {success: false, error: "Portfolio is full (max " + string(max_portfolio_size) + " positions)"}

    // Look up current market data
    set stock_data to run find_stock with symbol
    set current_price to purchase_price
    set ai_signal to "Unknown"
    set ai_confidence to 0.5
    set stock_name to upper(symbol)

    if stock_data is not equal nil:
        set current_price to stock_data.price
        set ai_signal to stock_data.signal
        set ai_confidence to stock_data.confidence
        set stock_name to stock_data.name

    // Calculate P&L
    set cost_basis to shares * purchase_price
    set current_value to shares * current_price
    set gain_loss to current_value - cost_basis
    set gain_loss_pct to 0.0
    if cost_basis is above 0:
        set gain_loss_pct to (gain_loss / cost_basis) * 100.0

    // Build position record
    set position_id to run make_id
    set position to {
        id: position_id,
        symbol: upper(symbol),
        name: stock_name,
        shares: shares,
        purchase_price: purchase_price,
        current_price: current_price,
        cost_basis: cost_basis,
        current_value: current_value,
        gain_loss: gain_loss,
        gain_loss_pct: gain_loss_pct,
        ai_signal: ai_signal,
        ai_confidence: ai_confidence,
        added_at: now()
    }

    append position to portfolio

    // Compute portfolio totals
    set total_value to 0.0
    set total_cost to 0.0
    repeat for each pos in portfolio:
        set total_value to total_value + pos.current_value
        set total_cost to total_cost + pos.cost_basis

    respond with {
        success: true,
        position: position,
        portfolio_summary: {
            total_positions: len(portfolio),
            total_value: total_value,
            total_cost: total_cost,
            total_gain_loss: total_value - total_cost
        },
        message: "Added " + upper(symbol) + " x" + string(shares) + " @ $" + string(purchase_price)
    }

// ── POST /api/v1/alerts/create ────────────────────────────────────
to create_alert with request:
    purpose: "Create a price alert that triggers when a stock crosses a target price"

    set symbol to request.stock_symbol
    set target to request.price_target
    set condition to request.alert_condition_above_below

    // Validate
    if symbol is empty:
        respond with {success: false, error: "Stock symbol is required"}
    if target is empty:
        respond with {success: false, error: "Price target is required"}
    if target is below 0:
        respond with {success: false, error: "Price target must be a positive number"}
    if len(alerts) is above max_alerts:
        respond with {success: false, error: "Alert limit reached (max " + string(max_alerts) + ")"}

    // Default condition to "above" if not specified
    if condition is not equal "above":
        if condition is not equal "below":
            set condition to "above"

    // Get current price for context
    set stock_data to run find_stock with symbol
    set current_price to nil
    if stock_data is not equal nil:
        set current_price to stock_data.price

    // Build alert record
    set alert_id to "alt-" + string(next_id)
    set next_id to next_id + 1
    set alert to {
        id: alert_id,
        symbol: upper(symbol),
        price_target: target,
        condition: condition,
        current_price: current_price,
        status: "active",
        created_at: now()
    }

    append alert to alerts

    respond with {
        success: true,
        alert: alert,
        message: "Alert created: notify when " + upper(symbol) + " goes " + condition + " $" + string(target)
    }

// ── GET /api/v1/stocks ────────────────────────────────────────────
to get_stocks:
    purpose: "Return all tracked stocks with current prices and AI signals"
    respond with {
        stocks: market_data,
        count: len(market_data),
        last_updated: now()
    }

// ── GET /api/v1/portfolio ─────────────────────────────────────────
to get_portfolio:
    purpose: "Return all portfolio positions with current valuations and totals"
    set total_value to 0.0
    set total_cost to 0.0
    repeat for each pos in portfolio:
        set total_value to total_value + pos.current_value
        set total_cost to total_cost + pos.cost_basis

    set total_gain to total_value - total_cost
    set total_gain_pct to 0.0
    if total_cost is above 0:
        set total_gain_pct to (total_gain / total_cost) * 100.0

    respond with {
        positions: portfolio,
        summary: {
            total_positions: len(portfolio),
            total_value: total_value,
            total_cost: total_cost,
            total_gain: total_gain,
            total_gain_pct: total_gain_pct
        }
    }

// ── GET /api/v1/alerts ────────────────────────────────────────────
to get_alerts:
    purpose: "Return all price alerts"
    set active_count to 0
    repeat for each a in alerts:
        if a.status is equal "active":
            set active_count to active_count + 1

    respond with {
        alerts: alerts,
        total: len(alerts),
        active: active_count
    }

// ── GET /health ───────────────────────────────────────────────────
to health_check:
    purpose: "Service health check"
    respond with {
        status: "ok",
        service: "neuraledge-stock",
        version: "1.0.0",
        portfolio_positions: len(portfolio),
        active_alerts: len(alerts),
        tracked_stocks: len(market_data)
    }

// ── API Route Table ───────────────────────────────────────────────
api:
    POST /api/v1/portfolio/analyze  runs analyze_portfolio
    POST /api/v1/alerts/create      runs create_alert
    GET  /api/v1/stocks             runs get_stocks
    GET  /api/v1/portfolio          runs get_portfolio
    GET  /api/v1/alerts             runs get_alerts
    GET  /health                    runs health_check
