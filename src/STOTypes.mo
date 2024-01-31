/**
 * Module     : STOTypes.mo
 * Author     : ICLighthouse Team
 * Stability  : Experimental
 * Description: Strategic orders: Professional orders and Stop loss orders.
 * Refers     : https://github.com/iclighthouse/
 */
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import List "mo:base/List";
import Trie "mo:base/Trie";
import Blob "mo:base/Blob";
import Binary "Binary";
import OB "OrderBook";

module {
    public type Txid = Blob;
    public type Sa = [Nat8];
    public type AccountId = Blob;
    public type ICRC1Account = {owner: Principal; subaccount: ?Blob; };
    public type Address = Text;
    public type Nonce = Nat;
    public type Amount = Nat;
    public type Timestamp = Nat; // seconds
    public type Price = Nat;
    public type OrderSide = { #Sell; #Buy; };
    public type Soid = Nat;
    public type Ppm = Nat; //  1 / 1000000
    public type STOrderRecords = Trie.Trie<Soid, STOrder>; 
    public type UserProOrderList = Trie.Trie<AccountId, List.List<Soid>>; // Excluding Stop Loss Orders; UserOrderCount <= 5; 
    public type ActiveProOrderList = List.List<Soid>; // Excluding Stop Loss Orders
    public type UserStopLossOrderList = Trie.Trie<AccountId, List.List<Soid>>; // Stop Loss Orders; UserOrderCount <= 10; 
    public type ActiveStopLossOrderList = {buy: List.List<(Soid, trigger: Price)>; sell: List.List<(Soid, trigger: Price)> }; // Stop Loss Orders
    public type STOrderTxids = Trie.Trie<Txid, Soid>; 

    public type Setting = {
        poFee1: Nat; //Token1
        poFee2: Float; 
        sloFee1: Nat; //Token1
        sloFee2: Float; 
        gridMaxPerSide: Nat; 
        proCountMax: Nat;
        stopLossCountMax: Nat;
    };
    public type STType = { #StopLossOrder; #GridOrder; #IcebergOrder; #VWAP; #TWAP }; // {#StopLossOrder; #GridOrder; #IcebergOrder; #VWAP; #TWAP }; 
    public type STStrategy = { 
        #StopLossOrder: StopLossOrder;
        #GridOrder: GridOrder; 
        #IcebergOrder: IcebergOrder;
        #VWAP: VWAP;
        #TWAP: TWAP;
    };
    public type STStats = {
        orderCount: Nat;
        errorCount: Nat;
        totalInAmount: {token0: Amount; token1: Amount};
        totalOutAmount: {token0: Amount; token1: Amount};
    };
    public type STStatus = {#Running; #Stopped; #Deleted };
    public type STOrder = {
        soid: Soid;
        icrc1Account: ICRC1Account;
        stType: STType;
        strategy: STStrategy;
        stats: STStats;
        status: STStatus;
        initTime: Timestamp;
        triggerTime: Timestamp;
        pendingOrders: { buy: [(?Txid, Price, quantity: Nat)]; sell: [(?Txid, Price, quantity: Nat)] }; // disordered
    };
    // StopLossOrder
    public type Condition = {
        triggerPrice: Price;
        order: { side: OrderSide; quantity: Nat; price: Price; };
    };
    public type TriggeredOrder = {
        triggerPrice: Price;
        order: { side: OrderSide; quantity: Nat; price: Price; };
    };
    public type StopLossOrder = {
        condition: Condition;
        triggeredOrder: ?TriggeredOrder;
    };
    // GridOrder
    public type GridOrderSetting = {
        lowerLimit: Price;
        upperLimit: Price;
        spread: {#Arith: Price; #Geom: Ppm };
        amount: {#Token0: Nat; #Token1: Nat; #Percent: ?Ppm };
    };
    public type GridSetting = {
        initPrice: Price; // Not allowed to be modified
        lowerLimit: Price;
        upperLimit: Price;
        gridCountPerSide: Nat; // <= 5 (vip-maker <= 10)
        spread: {#Arith: Price; #Geom: Ppm };
        amount: {#Token0: Nat; #Token1: Nat; #Percent: ?Ppm }; // #Percent(null) = ppmFactor; 
        // Note: only one #Percent way strategy order can be set up, otherwise it will cause a quantity calculation conflict.
        ppmFactor: ?Nat; //  1000000 * 1/n * (n ** (1/10))
    };
    // public type GridProgress = {
    //     ppmFactor: ?{buy: Nat; sell: Nat}; //  1000000 * 1/n * (n ** (1/10))
    //     gridPrices: { buy: [Price]; sell: [Price] };  // ordered
    // };
    public type GridPrices = {midPrice: ?Price; buy: [Price]; sell: [Price] };
    public type GridOrder = {
        setting: GridSetting;
        level1Filled: ?{ buy1: Amount; sell1: Amount};
        filter: ?{
            gridTop : Price;
            buyingBlankLocked : [(gridTop: Price, upperLimit: Price)];
            gridBottom : Price;
            sellingBlankLocked: [(lowerLimit: Price, gridBottom: Price)];
        };
        gridPrices: GridPrices;  // ordered
    };
    // IcebergOrder
    public type IcebergOrderSetting = {
        startingTime: Timestamp; // seconds
        endTime: Timestamp;
        order: {side: OB.OrderSide; price: Price; };
        amountPerTrigger: {#Token0: Nat; #Token1: Nat}; 
        totalLimit: {#Token0: Nat; #Token1: Nat};
    };
    public type IcebergOrder = {
        setting: IcebergOrderSetting;
        lastTxid: ?Blob;
    };
    // VWAP
    public type VWAPSetting = {
        startingTime: Timestamp; // seconds
        endTime: Timestamp;
        order: {side: OB.OrderSide; priceSpread: Price; priceLimit: Price; };
        amountPerTrigger: {#Token0: Nat; #Token1: Nat}; 
        totalLimit: {#Token0: Nat; #Token1: Nat};
        triggerVol: {#Arith: Nat; #Geom: Ppm }; // vol of token1; #Geom: 24h_vol * Ppm / 1000000
    };
    public type VWAP = {
        setting: VWAPSetting;
        lastVol: ?Nat; // total vol of token1
    };
    // TWAP
    public type TWAPSetting = {
        startingTime: Timestamp; // seconds
        endTime: Timestamp;
        order: {side: OB.OrderSide; priceSpread: Price; priceLimit: Price; };
        amountPerTrigger: {#Token0: Nat; #Token1: Nat}; 
        totalLimit: {#Token0: Nat; #Token1: Nat};
        triggerInterval: Nat; // seconds
    };
    public type TWAP = {
        setting: TWAPSetting;
        lastTime: ?Timestamp;
    };

    public type Self = actor {
        sto_cancelPendingOrders : shared (_soid: Soid, _sa: ?Sa) -> async ();
        sto_createProOrder : shared (_arg: {
            #GridOrder: GridOrderSetting;
            #IcebergOrder: IcebergOrderSetting;
            #VWAP: VWAPSetting;
            #TWAP: TWAPSetting;
        }, _sa: ?Sa) -> async Soid;
        sto_updateProOrder : shared (_soid: Soid, _arg: {
            #GridOrder: {
                lowerLimit: ?Price;
                upperLimit: ?Price;
                spread: ?{#Arith: Price; #Geom: Ppm };
                amount: ?{#Token0: Nat; #Token1: Nat; #Percent: ?Ppm };
                status: ?STStatus;
            };
            #IcebergOrder: {setting: ?IcebergOrderSetting; status: ?STStatus;};
            #VWAP: {setting: ?VWAPSetting; status: ?STStatus;};
            #TWAP: {setting: ?TWAPSetting; status: ?STStatus;};
        }, _sa: ?Sa) -> async Soid;
        sto_createStopLossOrder : shared (_arg: {
            triggerPrice: Price;
            order: { side: OB.OrderSide; quantity: Nat; price: Price; };
        }, _sa: ?Sa) -> async Soid;
        sto_updateStopLossOrder : shared (_soid: Soid, _arg: {
            triggerPrice: ?Price;
            order: ?{ side: OB.OrderSide; quantity: Nat; price: Price; };
            status: ?STStatus;
        }, _sa: ?Sa) -> async Soid;
        sto_getStratOrder : shared query (_soid: Soid) -> async ?STOrder;
        sto_getStratOrderByTxid : shared query (_txid: Txid) -> async ?STOrder;
        sto_getAccountProOrders : shared query (_a: Address) -> async [STOrder];
        sto_getAccountStopLossOrders : shared query (_a: Address) -> async [STOrder];
        sto_getConfig : shared query () -> async Setting;
    };
}