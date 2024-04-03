// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Streamer is Ownable {
	event Opened(address, uint256);
	event Challenged(address);
	event Withdrawn(address, uint256);
	event Closed(address);

	mapping(address => uint256) balances;
	mapping(address => uint256) canCloseAt;

	function fundChannel() public payable {
		require(
			balances[msg.sender] == 0,
			"There is already stablished channel."
		);
		balances[msg.sender] = msg.value;
		emit Opened(msg.sender, msg.value);
	}

	function timeLeft(address channel) public view returns (uint256) {
		if (canCloseAt[channel] == 0 || canCloseAt[channel] < block.timestamp) {
			return 0;
		}

		return canCloseAt[channel] - block.timestamp;
	}

	function withdrawEarnings(Voucher calldata voucher) public onlyOwner {
		bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));

		bytes memory prefixed = abi.encodePacked(
			"\x19Ethereum Signed Message:\n32",
			hashed
		);
		bytes32 prefixedHashed = keccak256(prefixed);

		address signer = ecrecover(
			prefixedHashed,
			voucher.sig.v,
			voucher.sig.r,
			voucher.sig.s
		);
		require(balances[signer] != 0, "The signer is not exist.");
		console.log(voucher.updatedBalance);
		require(
			balances[signer] >= voucher.updatedBalance,
			"The signer has less balance than the required payment."
		);
		uint256 payment = balances[signer] - voucher.updatedBalance;
		require(payment != 0, "It is a redundent withdraw.");
		balances[signer] = voucher.updatedBalance;
		address owner = msg.sender;
		address(owner).call{ value: payment }("");
		emit Withdrawn(owner, payment);
	}

	function challengeChannel() public {
		require(balances[msg.sender] != 0, "You don't have an active channel.");
		canCloseAt[msg.sender] = block.timestamp + 30 seconds;
		emit Challenged(msg.sender);
	}

	function defundChannel() public {
		require(balances[msg.sender] != 0, "You don't have an active channel.");
		require(
			canCloseAt[msg.sender] != 0,
			"You didn't register a challange."
		);
		require(
			canCloseAt[msg.sender] < block.timestamp,
			"The channel hasn't been closed yet."
		);
		address(msg.sender).call{ value: balances[msg.sender] }("");
		balances[msg.sender] = 0;
		emit Closed(msg.sender);
	}

	struct Voucher {
		uint256 updatedBalance;
		Signature sig;
	}
	struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
	}
}
