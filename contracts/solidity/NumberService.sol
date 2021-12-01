pragma solidity ^0.8.3;
contract numberService { //TODO: Currently not collecting any fees
    //Contract Owner
    address payable owner;
    uint256 ownerBalance;

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
        address owner;
        uint256 price;
    }
    mapping(string=>listingInformation) number2listing;

    uint costOfFreeNumber = 1;

    constructor () public {
        owner = payable(msg.sender);
    }

    function receiveNumber(address receiver, string memory number) private {
        number2owner[number] = receiver;
        owner2account[receiver].ownedNumbers.push(number);
    }

    function transferNumber(address receiver, address donor, string calldata number, uint256 pay) private {
        number2owner[number] = receiver;
        string[] memory donorNumbers = owner2account[donor].ownedNumbers;
        for (uint i = 0; i < donorNumbers.length - 1; i++) {
            if(keccak256(bytes(donorNumbers[i])) == keccak256(bytes(number))){
                donorNumbers[i] = donorNumbers[donorNumbers.length-1];
                delete donorNumbers[donorNumbers.length - 1];
            }
        }
        owner2account[receiver].ownedNumbers.push(number);
        owner2account[donor].accountBalance += pay;

    }

    function checkOwner(string calldata number) view external returns (address) {
        if(number2owner[number] == address(0x0)){
            return address(0x0);
        }
        return owner; //TODO: Look up nicknames
    }

    function seeTransactions() view external {

    }

    function seeOwnedNumbers() view external returns (string[] memory) {
        return owner2account[msg.sender].ownedNumbers;
    }

    function seeBalance() view external {
        return owner2account[msg.sender].accountBalance;
    }

    function withdrawMoney(address payable sendTo) external {
        uint256 amount = owner2account[msg.sender].accountBalance;
        if(msg.sender == owner) {
            amount += ownerBalance;
        }
        sendTo.transfer(amount);
    }

    function listNumber(string calldata number, uint256 price) external {
        require(number2owner[number]==msg.sender, "Trying to list number that you don't own!");
        number2listing[number] = listingInformation(msg.sender, price);
    }

    function buyNumber(string calldata number) payable external {
        if(number2owner[number]==address(0x0)) {
            require(msg.value == costOfFreeNumber, "Trying to buy a free number, with an inadequate amount of ether");
            receiveNumber(msg.sender, number);
            ownerBalance += costOfFreeNumber;
        } else if(number2listing[number].owner == address(0x0)) {
            require(msg.value == number2listing[number].price);
            address donor = number2listing[number].owner;
            transferNumber(msg.sender, donor, number, msg.value);
        } else {
            require(false, "Number is neither available nor listed by it's owner");
        }

    }

}