-- 引入SHA256加密库（用于生成区块哈希，保证数据不可篡改）
-- 先安装：luarocks install luacrypto
local crypto = require("crypto")

-- ===================== 1. 定义核心数据结构 =====================
-- 区块链（存储所有区块）
local blockchain = {}
-- 账户表（快速查询余额，区块链是唯一真相源，此表仅做缓存）
local accounts = {}
-- 商品清单（商店商品库）
local products = {
    ["apple"] = {name = "苹果", price = 5, stock = 100},
    ["milk"] = {name = "牛奶", price = 10, stock = 200},
    ["bread"] = {name = "面包", price = 8, stock = 150}
}

-- ===================== 2. 工具函数 =====================
-- 生成区块哈希（核心：保证数据不可篡改）
local function calculate_hash(block)
    local data = block.index .. block.timestamp .. block.prev_hash .. block.transaction .. block.nonce
    return crypto.digest("sha256", data)
end

-- 获取当前时间戳
local function get_timestamp()
    return os.time()
end

-- 初始化账户（首次使用时创建）
local function init_account(account_id)
    if not accounts[account_id] then
        accounts[account_id] = {
            balance = 0,       -- 账户余额
            purchases = {}     -- 购买的商品记录
        }
    end
end

-- ===================== 3. 区块链核心功能 =====================
-- 创建创世区块（区块链的第一个区块）
local function create_genesis_block()
    local genesis_block = {
        index = 1,
        timestamp = get_timestamp(),
        prev_hash = "0",  -- 创世区块没有上一个哈希，用0表示
        transaction = "Genesis Block: 商店系统初始化",
        nonce = 0,
        hash = ""
    }
    genesis_block.hash = calculate_hash(genesis_block)
    table.insert(blockchain, genesis_block)
    print("创世区块创建完成：", genesis_block.hash)
end

-- 添加交易区块（核心：记录购买/充值等交易）
local function add_transaction_block(from_account, to_account, amount, product_id)
    -- 1. 校验基础参数
    init_account(from_account)
    init_account(to_account)
    
    -- 2. 处理交易逻辑（区分充值和购买）
    local transaction_desc
    if product_id then
        -- 购买商品逻辑
        local product = products[product_id]
        if not product then
            return false, "商品不存在：" .. product_id
        end
        if product.stock <= 0 then
            return false, "商品售罄：" .. product.name
        end
        if accounts[from_account].balance < product.price then
            return false, "余额不足，当前余额：" .. accounts[from_account].balance .. "，商品价格：" .. product.price
        end
        
        -- 扣减余额、扣减库存、记录购买
        accounts[from_account].balance = accounts[from_account].balance - product.price
        product.stock = product.stock - 1
        table.insert(accounts[from_account].purchases, {
            product = product.name,
            price = product.price,
            time = os.date("%Y-%m-%d %H:%M:%S", get_timestamp())
        })
        
        -- 商家账户收款（to_account为商家账户）
        accounts[to_account].balance = accounts[to_account].balance + product.price
        
        transaction_desc = string.format(
            "用户%s购买%s，花费%d元，商家%s收款%d元，商品剩余库存%d",
            from_account, product.name, product.price, to_account, product.price, product.stock
        )
    else
        -- 充值逻辑（to_account为空则是充值，from_account为系统）
        if from_account == "system" then
            accounts[to_account].balance = accounts[to_account].balance + amount
            transaction_desc = string.format("系统向用户%s充值%d元，当前余额：%d", to_account, amount, accounts[to_account].balance)
        else
            return false, "无效的交易类型"
        end
    end

    -- 3. 创建新区块
    local last_block = blockchain[#blockchain]
    local new_block = {
        index = last_block.index + 1,
        timestamp = get_timestamp(),
        prev_hash = last_block.hash,
        transaction = transaction_desc,
        nonce = 0,
        hash = ""
    }
    new_block.hash = calculate_hash(new_block)
    
    -- 4. 添加到区块链
    table.insert(blockchain, new_block)
    return true, "交易成功，区块哈希：" .. new_block.hash
end

-- ===================== 4. 查询功能 =====================
-- 查询账户余额
local function query_balance(account_id)
    init_account(account_id)
    return accounts[account_id].balance
end

-- 查询账户购买记录
local function query_purchases(account_id)
    init_account(account_id)
    return accounts[account_id].purchases
end

-- 查询区块链完整信息
local function query_blockchain()
    return blockchain
end

-- 验证区块链完整性（防篡改）
local function verify_blockchain()
    for i = 2, #blockchain do
        local current = blockchain[i]
        local prev = blockchain[i-1]
        -- 校验当前区块哈希是否正确
        if current.hash ~= calculate_hash(current) then
            return false, "区块" .. i .. "哈希篡改"
        end
        -- 校验区块链接是否断裂
        if current.prev_hash ~= prev.hash then
            return false, "区块" .. i .. "与上一区块链接断裂"
        end
    end
    return true, "区块链完整，无篡改"
end

-- ===================== 5. 测试示例 =====================
-- 初始化
create_genesis_block()
local merchant_account = "store_001"  -- 商家账户
local user_account = "user_001"       -- 普通用户账户

-- 1. 给用户充值100元
local success, msg = add_transaction_block("system", user_account, 100, nil)
print(msg)  -- 输出：交易成功，区块哈希：xxx

-- 2. 查询用户余额
local balance = query_balance(user_account)
print("用户余额：", balance)  -- 输出：100

-- 3. 用户购买苹果
success, msg = add_transaction_block(user_account, merchant_account, nil, "apple")
print(msg)  -- 输出：交易成功，区块哈希：xxx

-- 4. 查询用户购买记录
local purchases = query_purchases(user_account)
print("用户购买记录：")
for i, p in ipairs(purchases) do
    print(string.format("%d. %s - %d元 - %s", i, p.product, p.price, p.time))
end

-- 5. 验证区块链是否被篡改
success, msg = verify_blockchain()
print(msg)  -- 输出：区块链完整，无篡改

-- 6. 尝试篡改数据（测试防篡改）
blockchain[3].transaction = "用户user_001购买苹果，花费1元"  -- 篡改交易金额
success, msg = verify_blockchain()
print(msg)  -- 输出：区块3哈希篡改