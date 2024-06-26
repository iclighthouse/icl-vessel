import ICDex "ICDexTypes";

module {
    public type InitArgs = {
        creator: AccountId;
        allow: {#Public; #Private};
        pair: Principal;
        unitSize: Nat;
        name: Text;
        token0: Principal;
        token0Std: ICDex.TokenStd;
        token1: Principal;
        token1Std: ICDex.TokenStd;
        lowerLimit: Nat; //Price
        upperLimit: Nat; //Price
        spreadRate: Nat; // ppm  x/1000000
        threshold: Amount;
        volFactor: Nat; // multi 
    };
    public type Config = {
        lowerLimit: ?Nat; //Price
        upperLimit: ?Nat; //Price
        spreadRatePpm: ?Nat; // ppm x/1000000
        threshold: ?Amount; //token1
        volFactor: ?Nat; // 1\2\3..
        withdrawalFeePpm: ?Nat; // ppm x/1000000
    };
    public type AccountId = Blob;
    public type ICRC1Account = {owner: Principal; subaccount: ?Blob; };
    public type Address = Text;
    public type Txid = Blob;
    public type Toid = Nat;
    public type Amount = Nat;
    public type Price = Nat;
    public type Shares = Nat;
    public type Sa = [Nat8];
    public type Nonce = Nat;
    public type Data = Blob;
    public type Timestamp = Nat;
    public type CanisterId = Principal;
    public type PoolBalance = {
        balance0: Amount; 
        balance1: Amount;
        ts: Timestamp
    };
    public type UnitNetValue = {
        ts: Timestamp; 
        token0: Nat; 
        token1: Nat; 
        price: Price;
        shares: Nat; // * 10**sharesDecimal
    };
    public type ShareWeighted = {
        shareTimeWeighted: Nat; 
        updateTime: Timestamp; 
    };
    public type Liquidity = {
        token0: Amount;
        token1: Amount;
        shares: Amount;
        shareDecimals: Nat8;
        shareWeighted: { shareTimeWeighted: Nat; updateTime: Timestamp; };
        unitValue: (token0: Amount, token1: Amount);
    };
    public type TrieList<K, V> = {data: [(K, V)]; total: Nat; totalPage: Nat; };
    public type ListPage = Nat;
    public type ListSize = Nat;
    public type Event = { //Timestamp = seconds
        #init : {initArgs: InitArgs};
        #start: { message: ?Text };
        #suspend: { message: ?Text };
        #lock: { message: ?Text };
        #unlock: { message: ?Text };
        #changeOwner: {newOwner: Principal};
        #config: {setting: Config };
        #add: {#ok: {account: ICRC1Account; shares: Shares; token0: Amount; token1: Amount; toids: [Nat]}; #err: {account: ICRC1Account; depositToken0: Amount; depositToken1: Amount; toids: [Nat]}};
        #remove: {#ok: {account: ICRC1Account; shares: Shares; token0: Amount; token1: Amount; toid: ?Nat}; #err: {account: ICRC1Account; addPoolToken0: Amount; addPoolToken1: Amount; toid: ?Nat}};
        #fallback: {account: ICRC1Account; token0: Amount; token1: Amount; toids: [Nat]};
        #deposit: {account: ICRC1Account; token0: Nat; token1: Nat;};
        #withdraw: {account: ICRC1Account; token0: Nat; token1: Nat; toid: ?Nat};
        #dexDeposit: {token0: Nat; token1: Nat; toid: ?Nat}; 
        #dexWithdraw: {token0: Nat; token1: Nat; toid: ?Nat}; 
        #updateGridOrder: {soid: ?Nat; toid: ?Nat};
        #createGridOrder: {toid: ?Nat};
        #deleteGridOrder: {soid: ?Nat; toid: ?Nat};
        #updateUnitNetValue: { 
            pairBalance: ?{token0: {locked: Amount; available: Amount}; token1: {locked: Amount; available: Amount}};
            localBalance: PoolBalance;
            poolBalance: PoolBalance;
            poolShares: Shares;
            unitNetValue: UnitNetValue;
        };
    };
    public type Self = actor {
        getDepositAccount: shared query (_account: Address) -> async (ICRC1Account, Address);
        fallback: shared (_sa: ?Sa) -> async (value0: Amount, value1: Amount);
        add: shared (_token0: Amount, _token1: Amount, _sa: ?Sa) -> async Shares;
        remove: shared (_shares: Amount, _sa: ?Sa) -> async (value0: Amount, value1: Amount);
        getAccountShares: shared query (_account: Address) -> async (Shares, ShareWeighted);
        getAccountVolUsed: shared query (_account: Address) -> async Nat;
        getUnitNetValues: shared query () -> async {shareUnitSize: Nat; data: [UnitNetValue]};
        info: shared query () -> async {
            version: Text;
            name: Text;
            paused: Bool;
            initialized: Bool;
            sysTransactionLock: Bool;
            sysGlobalLock: ?Bool;
            visibility: {#Public; #Private};
            creator: AccountId;
            withdrawalFee: Float;
            poolThreshold: Amount;
            volFactor: Nat; // token1
            gridSoid: [?Nat];
            shareDecimals: Nat8;
            pairInfo: {
                pairPrincipal: Principal;
                pairUnitSize: Nat;
                token0: (Principal, Text, ICDex.TokenStd);
                token1: (Principal, Text, ICDex.TokenStd);
            };
            gridSetting: {
                gridLowerLimit: Price;
                gridUpperLimit: Price;
                gridSpread : Price;
            };
        };
        stats: shared query () -> async {
            holders: Nat;
            poolBalance: PoolBalance;
            poolLocalBalance: PoolBalance;
            poolShares: Shares;
            poolShareWeighted: ShareWeighted;
            latestUnitNetValue: UnitNetValue;
        };
        stats2: shared composite query () -> async {
            holders: Nat;
            poolBalance: PoolBalance;
            poolLocalBalance: PoolBalance;
            poolShares: Shares;
            poolShareWeighted: ShareWeighted;
            latestUnitNetValue: UnitNetValue;
            apy24h: {token0: Float; token1: Float; apy: ?Float};
            apy7d: {token0: Float; token1: Float; apy: ?Float};
        };
        // admin
        config: shared (_config: Config) -> async Bool;
        transactionLock: shared (_sysTransactionLock: ?{#lock; #unlock}, _sysGlobalLock: ?{#lock; #unlock}) -> async Bool;
        setPause: shared (_pause: Bool) -> async Bool;
        resetLocalBalance: shared () -> async PoolBalance;
        dexWithdraw: shared (_token0: Amount, _token1: Amount) -> async (token0: Amount, token1: Amount);
        dexDeposit: shared (_token0: Amount, _token1: Amount) -> async (token0: Amount, token1: Amount);
        deleteGridOrder: shared (_gridOrder: {#First; #Second}) -> async ();
        createGridOrder: shared (_gridOrder: {#First; #Second}) -> async ();
        cancelAllOrders: shared () -> async ();
    };
};