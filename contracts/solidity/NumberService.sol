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
    uint costOfNickname = 1;

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

    function checkOwnerOld(string calldata number) view external returns (string memory) { //TODO: Maybe give suspected owner as parameter and return boolean?
        address numberHolder = number2owner[number];
        if(numberHolder == address(0x0)){
            return "Unowned";
        } else if(keccak256(bytes(owner2account[numberHolder].number2nickname[number]))!=keccak256("")){
            return owner2account[numberHolder].number2nickname[number];
        } else {
            return string(abi.encodePacked(numberHolder));
        }
    }

    function checkOwner(string calldata number) view external returns (string memory) {
        address numberHolder = number2owner[number];
        if(numberHolder == address(0x0)){
            return "Unowned";
        } else if(keccak256(bytes(owner2account[numberHolder].number2nickname[number]))!=keccak256("")){
            return owner2account[numberHolder].number2nickname[number];
        } else {
            return toString(abi.encodePacked(numberHolder));
        }
    }

    function toString(bytes memory data) internal pure returns(string memory) { //Help function for check owner
        bytes memory alphabet = "0123456789abcdef"; //Hexa alphabet to translate bits to string

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function seeTransactions() view external { //TODO: Blockchain already does this for us?

    }

    function seeOwnedNumbers() view external returns (string[] memory) {
        return owner2account[msg.sender].ownedNumbers;
    }

    function seeBalance() view external returns (uint256) {
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
        } else if(number2listing[number].owner != address(0x0)) {
            require(msg.value == number2listing[number].price,"Inadequate price for listed number");
            address donor = number2listing[number].owner;
            transferNumber(msg.sender, donor, number, msg.value);
        } else {
            require(false, "Number is neither available nor listed by it's owner");
        }

    }

    function buyNickname(string calldata nickname, string calldata number) payable external {
        require(msg.value == costOfNickname, "Inadequate amount of ether for nickname");
        owner2account[msg.sender].number2nickname[number] = nickname;
    }

}