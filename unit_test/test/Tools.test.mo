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

import Tools "../../src/Tools";

let principal = "ltjnq-oy7yd-dwun5-f2jhg-gzerp-lx276-h4yi2-brlqt-sycwa-qxa5v-4ae";
let account = "501e9d25ec37ded7a89cc6138c711d8447524374bdb147d0e2bce6f65abeeeeb";

await test(
	"test arrayAppend",
	func() : async () {
		let arr1 : [Nat] = [1, 2, 3];
		let arr2 : [Nat] = [4, 5, 6];
		let result : [Nat] = Tools.arrayAppend<Nat>(arr1, arr2);
		expect.array(result, Nat.toText, Nat.equal).equal([1, 2, 3, 4, 5, 6]);
	},
);

await test(
	"test slice",
	func() : async () {
		let arr1 : [Nat] = [1, 2, 3, 4, 5];
		let result = Tools.slice<Nat>(arr1, 2, ?3);
		expect.array(result, Nat.toText, Nat.equal).equal([3, 4]);
	},
);

await test(
	"test principalArrToText",
	func() : async () {
		let pArr : [Nat8] = Blob.toArray(Principal.toBlob(Principal.fromText(principal)));
		let result = Tools.principalArrToText(pArr);
		expect.text(result).equal(principal);
	},
);

await test(
	"test principalBlob to principal",
	func() : async () {
		let pBlob : Blob = Principal.toBlob(Principal.fromText(principal));
		let result = Tools.principalBlobToPrincipal(pBlob);
		expect.principal(result).equal(Principal.fromText(principal));
	},
);

await test(
	"test generate subAccount",
	func() : async () {
		let principal_arr : [Nat8] = Blob.toArray(Principal.toBlob(Principal.fromText(principal)));
		let buffer = Buffer.Buffer<Nat8>(32);
		for (item in principal_arr.vals()) {
			buffer.add(item);
		};
		buffer.insert(0, Nat8.fromNat(principal_arr.size()));
		buffer.add(0);
		buffer.add(0);
		// blob "\1D\1F\C0\C7\6A\37\A5\D2\4E\63\64\91\7A\EF\AF\F8\FC\C2\34\18\AE\13\96\05\60\42\E0\ED\78\02\00\00"
		let sub = Buffer.toArray<Nat8>(buffer);
		let result : Blob = Blob.fromArray(Tools.getSubAccount(Principal.fromText(principal), 0));
		expect.blob(result).equal(Blob.fromArray(sub));
	},
);

await test(
	"test getSA",
	func() : async () {
		let sa : [Nat8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32];
		let result : [Nat8] = Tools.getSA(32);
		expect.array(result, Nat8.toText, Nat8.equal).equal(sa);
	},
);

await test(
	"test subToSA",
	func() : async () {
		let sub : [Nat8] = [29, 31, 192, 199, 106, 55, 165, 210, 78, 99, 100, 145, 122, 239, 175, 248, 252, 194, 52, 24, 174, 19, 150, 5, 96, 66, 224, 237, 120, 2, 0, 0];
		let result : [Nat8] = Tools.subToSA(sub);
		expect.array(result, Nat8.toText, Nat8.equal).equal(Array.freeze(Array.init<Nat8>(32, 0)));
	},
);

await test(
	"test subToPrincipal",
	func() : async () {
		let sub : [Nat8] = [29, 31, 192, 199, 106, 55, 165, 210, 78, 99, 100, 145, 122, 239, 175, 248, 252, 194, 52, 24, 174, 19, 150, 5, 96, 66, 224, 237, 120, 2, 0, 0];
		let result : Principal = Tools.subToPrincipal(sub);
		expect.principal(result).equal(Principal.fromText(principal));
	},
);

await test(
	"test subHexToPrincipal",
	func() : async () {
		let sub : Text = "1d1fc0c76a37a5d24e6364917aefaff8fcc23418ae1396056042e0ed78020000";
		let result : Principal = Tools.subHexToPrincipal(sub);
		expect.principal(result).equal(Principal.fromText(principal));
	},
);

await test(
	"test principalTextToAccount",
	func() : async () {
		let account : [Nat8] = [80, 30, 157, 37, 236, 55, 222, 215, 168, 156, 198, 19, 140, 113, 29, 132, 71, 82, 67, 116, 189, 177, 71, 208, 226, 188, 230, 246, 90, 190, 238, 235];
		let result : [Nat8] = Tools.principalTextToAccount(principal, ?[0]);
		expect.array(result, Nat8.toText, Nat8.equal).equal(account);
	},
);

await test(
	"test principalToAccount",
	func() : async () {
		let account : [Nat8] = [80, 30, 157, 37, 236, 55, 222, 215, 168, 156, 198, 19, 140, 113, 29, 132, 71, 82, 67, 116, 189, 177, 71, 208, 226, 188, 230, 246, 90, 190, 238, 235];
		let result : [Nat8] = Tools.principalToAccount(Principal.fromText(principal), ?[0]);
		expect.array(result, Nat8.toText, Nat8.equal).equal(account);
	},
);

await test(
	"test principalBlobToAccount",
	func() : async () {
		let account : [Nat8] = [80, 30, 157, 37, 236, 55, 222, 215, 168, 156, 198, 19, 140, 113, 29, 132, 71, 82, 67, 116, 189, 177, 71, 208, 226, 188, 230, 246, 90, 190, 238, 235];
		let result : [Nat8] = Tools.principalBlobToAccount(Principal.toBlob(Principal.fromText(principal)), ?[0]);
		expect.array(result, Nat8.toText, Nat8.equal).equal(account);
	},
);

await test(
	"test principalTextToAccountBlob",
	func() : async () {
		let account : Blob = Blob.fromArray([80, 30, 157, 37, 236, 55, 222, 215, 168, 156, 198, 19, 140, 113, 29, 132, 71, 82, 67, 116, 189, 177, 71, 208, 226, 188, 230, 246, 90, 190, 238, 235]);
		let result : Blob = Tools.principalTextToAccountBlob(principal, ?[0]);
		expect.blob(result).equal(account);
	},
);

await test(
	"test principalToAccountBlob",
	func() : async () {
		let account : Blob = Blob.fromArray([80, 30, 157, 37, 236, 55, 222, 215, 168, 156, 198, 19, 140, 113, 29, 132, 71, 82, 67, 116, 189, 177, 71, 208, 226, 188, 230, 246, 90, 190, 238, 235]);
		let result : Blob = Tools.principalToAccountBlob(Principal.fromText(principal), ?[0]);
		expect.blob(result).equal(account);
	},
);

await test(
	"test principalBlobToAccountBlob",
	func() : async () {
		let account : Blob = Blob.fromArray([80, 30, 157, 37, 236, 55, 222, 215, 168, 156, 198, 19, 140, 113, 29, 132, 71, 82, 67, 116, 189, 177, 71, 208, 226, 188, 230, 246, 90, 190, 238, 235]);
		let result : Blob = Tools.principalBlobToAccountBlob(Principal.toBlob(Principal.fromText(principal)), ?[0]);
		expect.blob(result).equal(account);
	},
);

await test(
	"test principalTextToAccountHex",
	func() : async () {
		let result : Text = Tools.principalTextToAccountHex(principal, ?[0]);
		expect.text(result).equal(account);
	},
);

await test(
	"test principalToAccountHex",
	func() : async () {
		let result : Text = Tools.principalToAccountHex(Principal.fromText(principal), ?[0]);
		expect.text(result).equal(account);
	},
);

await test(
	"test principalBlobToAccountHex",
	func() : async () {
		let result : Text = Tools.principalBlobToAccountHex(Principal.toBlob(Principal.fromText(principal)), ?[0]);
		expect.text(result).equal(account);
	},
);

await test(
	"test accountHexToAccountBlob",
	func() : async () {
		let accountBlob : Blob = Blob.fromArray([80, 30, 157, 37, 236, 55, 222, 215, 168, 156, 198, 19, 140, 113, 29, 132, 71, 82, 67, 116, 189, 177, 71, 208, 226, 188, 230, 246, 90, 190, 238, 235]);
		let result : ?Blob = Tools.accountHexToAccountBlob(account);
		expect.blob(Option.get<Blob>(result, Blob.fromArray([0]))).equal(accountBlob);
	},
);

await test(
	"test isValidAccount",
	func() : async () {
		let result : Bool = Tools.isValidAccount([80, 30, 157, 37, 236, 55, 222, 215, 168, 156, 198, 19, 140, 113, 29, 132, 71, 82, 67, 116, 189, 177, 71, 208, 226, 188, 230, 246, 90, 190, 238, 235]);
		expect.bool(result).equal(true);
	},
);
