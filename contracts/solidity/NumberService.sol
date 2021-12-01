pragma solidity ^0.8.3;
contract numberService { //TODO: Currently not collecting any fees
    //Contract Owner
    address payable owner;

    //User accounts
    struct account {
        mapping(string=>string) number2nickname;
        string[] ownedNumbers;
        uint256 accountBalance;
    }
    mapping(address=>account) owner2account;

    // Number registry
    mapping(string=>address) number2owner;

    // Marketplace
    struct listingInformation {
        uint256 price;
        address owner;
    }
    mapping(string=>listingInformation) number2listing;

    uint costOfFreeNumber = 1;

    constructor () public {
        owner = msg.sender;
    }

    function receiveNumber(address receiver, string number) private {
        number2owner[number] = receiver;
        owner2account[receiver].ownedNumbers.push(number);
    }

    function transferNumber(address receiver, address donor, string number, uint256 pay) private {
        number2owner[number] = receiver;
        string[] donorNumbers = owner2account[donor].ownedNumbers;
        for (uint i = 0; i < donorNumbers.length - 1; i++) {
            if(donorNumbers[i] == number){
                donorNumbers[i] = donorNumbers[donorNumbers.length-1];
                donorNumbers.pop();
            }
        }
        owner2account[receiver].ownedNumbers.push(number);
        owner2account[donor].accountBalance += pay;

    }

    function checkOwner(string number) view external returns (string) {
        if(number2owner[number] == 0x0){
            return "Unowned";
        }
        return owner; //TODO: Look up nicknames
    }

    function seeTransactions() view external {

    }

    function seeNumbers() view external {

    }

    function seeBalance() view external {

    }

    function withdrawMoney() external {

    }

    function listNumber(string number, uint256 price) external {
        require(number2owner[number]==msg.sender, "Trying to list number that you don't own!");
        number2listing[number] = listingInformation(msg.sender, price);
    }

    function buyNumber(string number) payable external {
        if(number2owner[number]==0x0) {
            require(msg.value == costOfFreeNumber, "Trying to buy a free number, with an inadequate amount of ether");
            receiveNumber(msg.sender, number);
        } else if(number2listing[number].owner == 0x0) {
            require(msg.value == number2listing.price);
            address owner = number2listing[number].owner;
            transferNumber(msg.sender, owner, number);
        } else {
            require(false, "Number is neither available nor listed by it's owner");
        }

    }

}