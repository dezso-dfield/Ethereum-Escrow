pragma solidity 0.8.20;

contract Escrow {
	address public arbiter;
	address public beneficiary;
	address public depositor;

	constructor(address _arbiter, address _beneficiary) payable {
		arbiter = _arbiter;
		beneficiary = _beneficiary;
		depositor = msg.sender;
	}

	event Approved(uint);

    modifier onlyArbiter {
        require((msg.sender == arbiter), "Not authorized");
        _;
    }
	
    function approve() external onlyArbiter {
		uint balance = address(this).balance;

		(bool success, ) = beneficiary.call{ value: balance }("");
		require(success);
		
		emit Approved(balance);
	}
}
