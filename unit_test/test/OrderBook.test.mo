import { test; suite; skip; expect } "mo:test/async";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Nat8 "mo:base/Nat8";
import Prelude "mo:base/Prelude";
import List "mo:base/List";

import OrderBook "../../src/OrderBook";
import Hex "../../src/Hex";

var orderBook : OrderBook.OrderBook = OrderBook.create();

await test(
	"test adjust",
	func() : async () {
		let result : Nat = OrderBook.adjust(1_000, 8);
		expect.nat(result).equal(1_000);
	},
);

await test(
	"test side",
	func() : async () {
		let order_price = {
			quantity = #Sell(1_000);
			price = 100_000_000;
		};
		let result : OrderBook.OrderSide = OrderBook.side(order_price);
		assert result == #Sell;
	},
);

await test(
	"test create",
	func() : async () {
		assert orderBook == { ask = null; bid = null };
	},
);

// _ob: OrderBook, _txid: Txid, _orderPrice: OrderPrice, _orderType: OrderType, _UNIT_SIZE: Nat
await suite(
	"test trade",
	func() : async () {
		await test(
			"test sell",
			func() : async () {
				let opt_txid = Hex.decode2("00000023f1bc8a6bc47c4a4df92a0e09c269082b9021539ff1e4715a7ef2fe8d");
				let txid = Blob.fromArray(Option.get<[Nat8]>(opt_txid, []));
				let order_price = {
					quantity = #Sell(100_000_000);
					price = 500_000_000;
				};
				let order_type = #LMT;
				let unit_size = 10_000_000;
				let res = OrderBook.trade(orderBook, txid, order_price, order_type, unit_size);
				orderBook := res.ob;
				assert orderBook == {
					ask = ?(("\00\00\00\23\F1\BC\8A\6B\C4\7C\4A\4D\F9\2A\0E\09\C2\69\08\2B\90\21\53\9F\F1\E4\71\5A\7E\F2\FE\8D", { price = 500_000_000; quantity = #Sell(100_000_000) }), null);
					bid = null;
				};
			},
		);
		await test(
			"test buy",
			func() : async () {
				let opt_txid = Hex.decode2("00000003b2bbe19669580e0c10aafea51e886f577080a23d21135f16ba731214");
				let txid = Blob.fromArray(Option.get<[Nat8]>(opt_txid, []));
				let order_price = {
					quantity = #Buy(50_000_000, 5_000_000_000);
					price = 500_000_000;
				};
				let order_type = #LMT;
				let unit_size = 10_000_000;
				let res = OrderBook.trade(orderBook, txid, order_price, order_type, unit_size);
				orderBook := res.ob;
				assert orderBook == {
					ask = ?(("\00\00\00\23\F1\BC\8A\6B\C4\7C\4A\4D\F9\2A\0E\09\C2\69\08\2B\90\21\53\9F\F1\E4\71\5A\7E\F2\FE\8D", { price = 500_000_000; quantity = #Sell(50_000_000) }), null);
					bid = null;
				};
			},
		);
	},
);

await test(
	"test get",
	func() : async () {
		let opt_txid = Hex.decode2("00000023f1bc8a6bc47c4a4df92a0e09c269082b9021539ff1e4715a7ef2fe8d");
		let txid = Blob.fromArray(Option.get<[Nat8]>(opt_txid, []));
		let res = OrderBook.get(orderBook, txid, null);
		assert res == ?{ price = 500_000_000; quantity = #Sell(50_000_000) };
	},
);

await test(
	"test inOrderBook",
	func() : async () {
		let opt_txid = Hex.decode2("00000023f1bc8a6bc47c4a4df92a0e09c269082b9021539ff1e4715a7ef2fe8d");
		let txid = Blob.fromArray(Option.get<[Nat8]>(opt_txid, []));
		let inOrderBook = OrderBook.inOrderBook(orderBook, txid);
		assert inOrderBook == true;
	},
);

await test(
	"test level1",
	func() : async () {
		let level1 = OrderBook.level1(orderBook);
		assert level1 == {
			bestAsk = { price = 500_000_000; quantity = 50_000_000 };
			bestBid = { price = 0; quantity = 0 };
		};
	},
);

await test(
	"test depth",
	func() : async () {
		let depth = OrderBook.depth(orderBook, null);
		assert depth == {
			ask = [{ price = 500_000_000; quantity = 50_000_000 }];
			bid = [];
		};
	},
);

await test(
	"test remove",
	func() : async () {
		let opt_txid = Hex.decode2("00000023f1bc8a6bc47c4a4df92a0e09c269082b9021539ff1e4715a7ef2fe8d");
		let txid = Blob.fromArray(Option.get<[Nat8]>(opt_txid, []));
		let remove = OrderBook.remove(orderBook, txid, null);
		assert remove == {
			ask = null;
			bid = null;
		};
	},
);

await test(
	"test clear",
	func() : async () {
		let opt_txid = Hex.decode2("00000023f1bc8a6bc47c4a4df92a0e09c269082b9021539ff1e4715a7ef2fe8d");
		let txid = Blob.fromArray(Option.get<[Nat8]>(opt_txid, []));
		let order_price = {
			quantity = #Sell(100_000_000);
			price = 500_000_000;
		};
		let order_type = #LMT;
		let unit_size = 10_000_000;
		let res = OrderBook.trade(orderBook, txid, order_price, order_type, unit_size);
		orderBook := res.ob;

		let clear = OrderBook.clear(orderBook);
		assert clear == {
			ask = null;
			bid = null;
		};
	},
);
