-- =============================================================================
-- Script de Seed para Hummingbot API - Dados Base
-- =============================================================================
-- Este script insere dados iniciais necessários para o funcionamento do sistema.
-- O script é idempotente e pode ser executado múltiplas vezes sem erros.
-- =============================================================================

-- Desativar verificação de chaves estrangeiras temporariamente
SET session_replication_role = replica;

-- =============================================================================
-- 1. Dados de Exchanges/Connectors Suportados
-- =============================================================================
-- Como não há tabela específica de exchanges no schema atual, 
-- criamos uma tabela de configuração se não existir

CREATE TABLE IF NOT EXISTS supported_connectors (
    id SERIAL PRIMARY KEY,
    connector_name VARCHAR(100) NOT NULL UNIQUE,
    connector_type VARCHAR(50) NOT NULL, -- 'cex', 'dex', 'gateway'
    network VARCHAR(100), -- NULL para CEX, preenchido para DEX (ex: solana-mainnet-beta)
    is_active BOOLEAN DEFAULT TRUE,
    min_order_size NUMERIC(30, 18) DEFAULT 0,
    max_order_size NUMERIC(30, 18),
    fee_pct NUMERIC(10, 6) DEFAULT 0.001,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir exchanges CEX populares
INSERT INTO supported_connectors (connector_name, connector_type, network, is_active, fee_pct)
VALUES
    -- CEX Exchanges
    ('binance', 'cex', NULL, TRUE, 0.001),
    ('binance_perpetual', 'cex', NULL, TRUE, 0.0002),
    ('bybit', 'cex', NULL, TRUE, 0.001),
    ('bybit_perpetual', 'cex', NULL, TRUE, 0.00055),
    ('kucoin', 'cex', NULL, TRUE, 0.001),
    ('kucoin_perpetual', 'cex', NULL, TRUE, 0.0008),
    ('okx', 'cex', NULL, TRUE, 0.0008),
    ('okx_perpetual', 'cex', NULL, TRUE, 0.0005),
    ('gate_io', 'cex', NULL, TRUE, 0.002),
    ('huobi', 'cex', NULL, TRUE, 0.002),
    ('coinbase_advanced', 'cex', NULL, TRUE, 0.006),
    ('bitget', 'cex', NULL, TRUE, 0.001),
    ('bitget_perpetual', 'cex', NULL, TRUE, 0.0006),
    -- DEX/Gateway Connectors
    ('jupiter', 'gateway', 'solana-mainnet-beta', TRUE, 0.002),
    ('raydium', 'gateway', 'solana-mainnet-beta', TRUE, 0.0025),
    ('meteora', 'gateway', 'solana-mainnet-beta', TRUE, 0.003),
    ('orca', 'gateway', 'solana-mainnet-beta', TRUE, 0.003),
    ('uniswap', 'gateway', 'ethereum-mainnet', TRUE, 0.003),
    ('pancakeswap', 'gateway', 'bsc-mainnet', TRUE, 0.0025),
    ('quickswap', 'gateway', 'polygon-mainnet', TRUE, 0.0025)
ON CONFLICT (connector_name) DO NOTHING;

-- =============================================================================
-- 2. Tipos de Executors Suportados
-- =============================================================================

CREATE TABLE IF NOT EXISTS executor_types (
    id SERIAL PRIMARY KEY,
    executor_type VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200),
    description TEXT,
    category VARCHAR(50), -- 'directional', 'market_making', 'arbitrage', 'gateway'
    is_active BOOLEAN DEFAULT TRUE,
    default_config JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir tipos de executors baseados nos controllers disponíveis
INSERT INTO executor_types (executor_type, display_name, description, category, is_active, default_config)
VALUES
    -- Directional Trading Executors
    ('bollinger_v1', 'Bollinger Bands v1', 'Estratégia baseada em Bandas de Bollinger v1', 'directional', TRUE, 
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "bb_length": 20, "bb_std": 2.0, "order_amount": 100}'::jsonb),
    ('bollinger_v2', 'Bollinger Bands v2', 'Estratégia baseada em Bandas de Bollinger v2', 'directional', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "bb_length": 20, "bb_std": 2.0, "order_amount": 100}'::jsonb),
    ('bollingrid', 'Bollinger Grid', 'Grid trading com Bandas de Bollinger', 'directional', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "grid_levels": 5, "order_amount": 50}'::jsonb),
    ('dman_v3', 'DMAN v3', 'Directional Market Making and Trading v3', 'directional', TRUE,
     '{"connector_name": "binance_perpetual", "trading_pair": "BTC-USDT", "leverage": 3, "position_mode": "ONEWAY"}'::jsonb),
    ('macd_bb_v1', 'MACD + Bollinger v1', 'Estratégia MACD combinada com Bandas de Bollinger', 'directional', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "macd_fast": 12, "macd_slow": 26, "macd_signal": 9}'::jsonb),
    ('supertrend_v1', 'Supertrend v1', 'Estratégia baseada em indicador Supertrend', 'directional', TRUE,
     '{"connector_name": "binance_perpetual", "trading_pair": "BTC-USDT", "supertrend_period": 10, "supertrend_multiplier": 3}'::jsonb),
    
    -- Market Making Executors
    ('dman_maker_v2', 'DMAN Maker v2', 'Directional Market Maker v2', 'market_making', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "bid_spread": 0.001, "ask_spread": 0.001}'::jsonb),
    ('pmm_dynamic', 'PMM Dynamic', 'Dynamic Pure Market Making', 'market_making', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "dynamic_spread": true, "base_spread": 0.001}'::jsonb),
    ('pmm_simple', 'PMM Simple', 'Simple Pure Market Making', 'market_making', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "bid_spread": 0.002, "ask_spread": 0.002}'::jsonb),
    
    -- Generic/Arbitrage Executors
    ('arbitrage_controller', 'Arbitrage Controller', 'Execução de arbitragem entre exchanges', 'arbitrage', TRUE,
     '{"primary_connector": "binance", "secondary_connector": "kucoin", "trading_pair": "BTC-USDT", "min_profit_pct": 0.005}'::jsonb),
    ('grid_strike', 'Grid Strike', 'Grid trading com strike price', 'arbitrage', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "grid_levels": 10, "strike_price": 50000}'::jsonb),
    ('hedge_asset', 'Hedge Asset', 'Hedge de posição em asset específico', 'arbitrage', TRUE,
     '{"connector_name": "binance_perpetual", "trading_pair": "BTC-USDT", "hedge_ratio": 1.0}'::jsonb),
    ('multi_grid_strike', 'Multi Grid Strike', 'Múltiplos grids com strike', 'arbitrage', TRUE,
     '{"connector_name": "binance", "trading_pairs": ["BTC-USDT", "ETH-USDT"], "grid_levels": 5}'::jsonb),
    ('pmm_adjusted', 'PMM Adjusted', 'Pure Market Making ajustado', 'market_making', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "adjustment_interval": 60}'::jsonb),
    ('pmm_mister', 'PMM Mister', 'Pure Market Making Mister', 'market_making', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "risk_factor": 0.5}'::jsonb),
    ('pmm_v1', 'PMM v1', 'Pure Market Making v1', 'market_making', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "order_refresh_time": 30}'::jsonb),
    ('quantum_grid_allocator', 'Quantum Grid Allocator', 'Alocação quântica em grid', 'arbitrage', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "allocation_strategy": "quantum"}'::jsonb),
    ('stat_arb', 'Statistical Arbitrage', 'Arbitragem estatística', 'arbitrage', TRUE,
     '{"connector_name": "binance", "trading_pair": "BTC-USDT", "lookback_period": 100}'::jsonb),
    ('xemm_multiple_levels', 'XEMM Multiple Levels', 'Cross-Exchange Market Making multi-nível', 'arbitrage', TRUE,
     '{"primary_connector": "binance", "secondary_connector": "kucoin", "trading_pair": "BTC-USDT"}'::jsonb),
    
    -- Gateway/LP Executors
    ('lp_rebalancer', 'LP Rebalancer', 'Rebalanceamento de liquidez em CLMM', 'gateway', TRUE,
     '{"connector": "meteora", "network": "solana-mainnet-beta", "pool_address": "", "rebalance_threshold": 0.05}'::jsonb)
ON CONFLICT (executor_type) DO NOTHING;

-- =============================================================================
-- 3. Configurações Padrão do Sistema
-- =============================================================================

CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value TEXT,
    config_type VARCHAR(50) DEFAULT 'string', -- 'string', 'number', 'boolean', 'json'
    description TEXT,
    is_editable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir configurações padrão
INSERT INTO system_config (config_key, config_value, config_type, description, is_editable)
VALUES
    ('default_connector', 'binance', 'string', 'Connector padrão para novas estratégias', TRUE),
    ('default_trading_pair', 'BTC-USDT', 'string', 'Par de trading padrão', TRUE),
    ('max_active_bots', '10', 'number', 'Número máximo de bots ativos simultâneos', TRUE),
    ('default_leverage', '1', 'number', 'Alavancagem padrão para perpetual', TRUE),
    ('max_order_size_usdt', '10000', 'number', 'Tamanho máximo de ordem em USDT', TRUE),
    ('enable_notifications', 'true', 'boolean', 'Habilitar notificações do sistema', TRUE),
    ('mqtt_broker_host', 'emqx', 'string', 'Host do broker MQTT', FALSE),
    ('mqtt_broker_port', '1883', 'number', 'Porta do broker MQTT', FALSE),
    ('gateway_url', 'http://host.docker.internal:15888', 'string', 'URL do Gateway', FALSE),
    ('supported_timeframes', '["1m","5m","15m","1h","4h","1d"]', 'json', 'Timeframes suportados para candles', FALSE),
    ('supported_order_types', '["MARKET","LIMIT","LIMIT_MAKER"]', 'json', 'Tipos de ordens suportadas', FALSE),
    ('health_check_interval', '60', 'number', 'Intervalo de health check em segundos', TRUE),
    ('position_sync_interval', '30', 'number', 'Intervalo de sincronização de posições em segundos', TRUE),
    ('order_refresh_interval', '10', 'number', 'Intervalo de refresh de ordens em segundos', TRUE)
ON CONFLICT (config_key) DO NOTHING;

-- =============================================================================
-- 4. Contas Padrão (se necessário)
-- =============================================================================

-- Inserir uma conta padrão para testes se não existir nenhuma
INSERT INTO account_states (account_name, connector_name)
SELECT 'master_account', 'binance'
WHERE NOT EXISTS (SELECT 1 FROM account_states LIMIT 1);

-- =============================================================================
-- 5. Trading Pairs Populares
-- =============================================================================

CREATE TABLE IF NOT EXISTS supported_trading_pairs (
    id SERIAL PRIMARY KEY,
    trading_pair VARCHAR(50) NOT NULL,
    connector_name VARCHAR(100) NOT NULL,
    base_asset VARCHAR(20) NOT NULL,
    quote_asset VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    min_order_size NUMERIC(30, 18),
    price_precision INTEGER DEFAULT 2,
    size_precision INTEGER DEFAULT 6,
    UNIQUE(trading_pair, connector_name)
);

-- Inserir pares populares para Binance
INSERT INTO supported_trading_pairs (trading_pair, connector_name, base_asset, quote_asset, is_active, min_order_size)
VALUES
    ('BTC-USDT', 'binance', 'BTC', 'USDT', TRUE, 0.0001),
    ('ETH-USDT', 'binance', 'ETH', 'USDT', TRUE, 0.001),
    ('BNB-USDT', 'binance', 'BNB', 'USDT', TRUE, 0.01),
    ('SOL-USDT', 'binance', 'SOL', 'USDT', TRUE, 0.1),
    ('XRP-USDT', 'binance', 'XRP', 'USDT', TRUE, 1),
    ('ADA-USDT', 'binance', 'ADA', 'USDT', TRUE, 1),
    ('DOGE-USDT', 'binance', 'DOGE', 'USDT', TRUE, 1),
    ('DOT-USDT', 'binance', 'DOT', 'USDT', TRUE, 0.1),
    ('AVAX-USDT', 'binance', 'AVAX', 'USDT', TRUE, 0.1),
    ('LINK-USDT', 'binance', 'LINK', 'USDT', TRUE, 0.1),
    ('BTC-USDT', 'binance_perpetual', 'BTC', 'USDT', TRUE, 0.0001),
    ('ETH-USDT', 'binance_perpetual', 'ETH', 'USDT', TRUE, 0.001),
    ('SOL-USDT', 'binance_perpetual', 'SOL', 'USDT', TRUE, 0.1)
ON CONFLICT (trading_pair, connector_name) DO NOTHING;

-- =============================================================================
-- 6. Atualizar timestamps
-- =============================================================================

-- Atualizar updated_at para registros recém-criados
UPDATE supported_connectors SET updated_at = NOW() WHERE updated_at IS NULL;
UPDATE system_config SET updated_at = NOW() WHERE updated_at IS NULL;

-- Reativar verificação de chaves estrangeiras
SET session_replication_role = DEFAULT;

-- =============================================================================
-- Log de conclusão
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Seed data inserido com sucesso!';
    RAISE NOTICE 'Connectors suportados: %', (SELECT COUNT(*) FROM supported_connectors);
    RAISE NOTICE 'Tipos de executors: %', (SELECT COUNT(*) FROM executor_types);
    RAISE NOTICE 'Configurações do sistema: %', (SELECT COUNT(*) FROM system_config);
    RAISE NOTICE 'Pares de trading: %', (SELECT COUNT(*) FROM supported_trading_pairs);
END $$;
