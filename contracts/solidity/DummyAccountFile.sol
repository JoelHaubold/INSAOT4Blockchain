pragma solidity ^0.8.3;

contract numberService {
    struct account {
        mapping(string=>string) number2nickname;
        string[] ownedNumbers;
    }

    address payable owner;
    mapping(address=>account) owner2account;
    mapping(string=>address) number2owner;

    constructor () public {
        owner = msg.sender;
    }

    function checkOwner() view external {

    }

    function seeTransactions() view external {

    }

    function seeNumbers() view external {

    }

    function seeBalance() view external {

    }

    function withdrawMoney() external {

    }


}