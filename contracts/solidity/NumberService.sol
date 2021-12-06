pragma solidity ^0.8.3;
contract numberService {
    //Contract Owner
    address payable numberProvider;
    uint256 ownerBalance;

    //User accounts
    struct account {
        mapping(string=>string) number2nickname;
        string[] ownedNumbers;
        uint256 accountBalance;
    }
    mapping(address=>account) owner2account;

    // Number registry
    struct numberInformation { //TODO: Actually set bool
        address owner;
        bool isBeeingRentedOrAuctionedOrListed; //If this is set true it means the number is already beeing listed/rented/auctioned. Set false when bought/returned/the auction finishes.
    }
    mapping(string=>numberInformation) number2numberInformation;

    // Marketplace
    mapping(string=>uint256) number2listingPrice;
    string[] listedNumbers;

    struct rentAvailableInformation {
        uint256 price;
        address originalOwner;
        uint256 endTimestamp;
        rentActiveInformation currentActiveRent;
    }
    struct rentActiveInformation {
        address renter;
        uint256 endTimestamp;
    }
    mapping(string=>rentAvailableInformation) number2rentContract;
    string[] availableRentNumbers;

    struct auctionStateInformation {
        address highestBider;
        uint256 highestBid;
        uint256 endTimestamp;
    }
    mapping(string=>auctionStateInformation) number2auctionState;
    string[] numbersBeingAuctioned;

    //Costs
    uint costOfFreeNumber = 10 wei;
    uint costOfNickname = 100 wei;
    //uint costOf60SecondsSubscription = 1 gwei;
    uint costOfReturnDelay = 1 wei;

    //Timeframes
    uint permittedRentReturnDelay = 60 seconds;

    constructor () {
        numberProvider = payable(msg.sender);
    }

    function receiveNumber(address receiver, string memory number) private {
        number2numberInformation[number] = numberInformation(receiver,false);
        owner2account[receiver].ownedNumbers.push(number);
    }

    function transferNumber(address receiver, address donor, string calldata number, uint256 pay) internal {
        number2numberInformation[number] = numberInformation(receiver,false);
        string[] storage donorNumbers = owner2account[donor].ownedNumbers; // Has to be storage to reflect changes
        for (uint i = 0; i < donorNumbers.length; i++) {
            if(compareStrings(donorNumbers[i], number)){
                donorNumbers[i] = donorNumbers[donorNumbers.length-1];
                donorNumbers.pop();
            }
        }
        owner2account[receiver].ownedNumbers.push(number);
        owner2account[donor].accountBalance += pay;
    }

    function compareStrings(string memory s1, string memory s2) internal pure returns (bool){
        return keccak256(bytes(s1)) == keccak256(bytes(s2));
    }

    function checkOwner(string calldata number, address suspectedOwner) view external returns (bool) {
        address numberHolder = number2numberInformation[number].owner;
        return suspectedOwner == numberHolder;
    }

    function checkOwner(string calldata number) view external returns (string memory) {
        address numberHolder = number2numberInformation[number].owner;
        if(numberHolder == address(0x0)){
            return "Unowned";
        } else if(!compareStrings(owner2account[numberHolder].number2nickname[number],"")){
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

    function seeOwnedNumbers() view external returns (string[] memory) {
        return owner2account[msg.sender].ownedNumbers;
    }

    function seeBalance() view external returns (uint256) {
        return owner2account[msg.sender].accountBalance;
    }

    function seeListedNumbers() view external returns (string[] memory) {
        return listedNumbers;
    }

    function seePriceOfListedNumber(string calldata number) view external returns (uint256) {
        return number2listingPrice[number];
    }

    function withdrawMoney(address payable sendTo) external {
        uint256 amount = owner2account[msg.sender].accountBalance;
        if(msg.sender == numberProvider) {
            amount += ownerBalance;
        }
        sendTo.transfer(amount);
    }

    function listNumber(string calldata number, uint256 price) external { //Check if number is already listed/auctioned/rented
        require(price>0,"Rent price has to be higher than 0");
        require(number2numberInformation[number].owner==msg.sender, "Trying to list number that you don't own!");
        require(number2numberInformation[number].isBeeingRentedOrAuctionedOrListed == false, "Number is not available for listing");
        number2numberInformation[number].isBeeingRentedOrAuctionedOrListed = true;
        number2listingPrice[number] = price;
        listedNumbers.push(number);
    }

    function buyNumber(string calldata number) payable external {
        if(number2numberInformation[number].owner==address(0x0)) {
            require(msg.value == costOfFreeNumber, "Trying to buy a free number, with an inadequate amount of ether");
            receiveNumber(msg.sender, number);
            ownerBalance += costOfFreeNumber;
        } else if(number2listingPrice[number] != 0) {
            require(msg.value == number2listingPrice[number],"Inadequate price for listed number");
            address donor = number2numberInformation[number].owner;
            transferNumber(msg.sender, donor, number, msg.value);
            number2listingPrice[number] = 0;
            for (uint i = 0; i < listedNumbers.length; i++) {
                if(compareStrings(listedNumbers[i], number)){
                    listedNumbers[i] = listedNumbers[listedNumbers.length-1];
                    listedNumbers.pop();
                }
            }
            number2numberInformation[number].isBeeingRentedOrAuctionedOrListed = false;
        } else {
            require(false, "Number is neither available nor listed by it's owner");
        }

    }

    function buyNickname(string calldata nickname, string calldata number) payable external {
        require(msg.value == costOfNickname, "Inadequate amount of ether for nickname");
        owner2account[msg.sender].number2nickname[number] = nickname;
    }

    //Functions for renting:

    function rentNumber(string calldata number, uint256 nmbrSeconds) payable external {
        require(number2rentContract[number].price!=0, "This number is not available to rent");
        require(number2rentContract[number].price+costOfReturnDelay==msg.value, "Inadequate price for renting this number");
        require(number2rentContract[number].currentActiveRent.renter == address(0x0), "This number is already beeing rented");
        uint256 endTimestamp = nmbrSeconds + block.timestamp;
        require(number2rentContract[number].endTimestamp > endTimestamp, "Trying to rent number for longer than its availability");
        number2rentContract[number].currentActiveRent = rentActiveInformation(msg.sender, endTimestamp);
        transferNumber(msg.sender, number2rentContract[number].originalOwner, number, msg.value);
        for (uint i = 0; i < availableRentNumbers.length; i++) {
            if(compareStrings(availableRentNumbers[i], number)){
                availableRentNumbers[i] = availableRentNumbers[availableRentNumbers.length-1];
                availableRentNumbers.pop();
            }
        }
    }

    function rentMakeNumberAvailable(string calldata number, uint256 price, uint256 nmbrSeconds) external {
        require(price>0,"Rent price has to be higher than 0");
        require(number2numberInformation[number].owner == msg.sender, "Trying to rent out a number that you don't own");
        require(number2numberInformation[number].isBeeingRentedOrAuctionedOrListed == false, "Number is not available for rent");
        number2numberInformation[number].isBeeingRentedOrAuctionedOrListed = true;
        availableRentNumbers.push(number);
        number2rentContract[number] = rentAvailableInformation(price, msg.sender, nmbrSeconds + block.timestamp, rentActiveInformation(address(0x0), 0));
    }

    function rentEndInstance(string calldata number) external {
        require(number2rentContract[number].currentActiveRent.endTimestamp < block.timestamp, "Rent session hasn't expired yet");
        uint256 feePayback = 0;
        if(number2rentContract[number].endTimestamp + permittedRentReturnDelay >= block.timestamp) {
            feePayback = costOfReturnDelay;
        }
        transferNumber(number2rentContract[number].originalOwner, number2rentContract[number].currentActiveRent.renter, number, feePayback);
        number2rentContract[number].currentActiveRent = rentActiveInformation(address(0x0), 0);
        availableRentNumbers.push(number);
    }

    function rentEndAvailability(string calldata number) external {
        require(number2rentContract[number].endTimestamp < block.timestamp, "Rent duration hasn't expired yet");
        if(number2rentContract[number].currentActiveRent.renter != address(0x0)) {
            this.rentEndInstance(number);
        }
        for (uint i = 0; i < availableRentNumbers.length; i++) {
            if(compareStrings(availableRentNumbers[i], number)){
                availableRentNumbers[i] = availableRentNumbers[availableRentNumbers.length-1];
                availableRentNumbers.pop();
            }
        }
        number2numberInformation[number].isBeeingRentedOrAuctionedOrListed = false;
        number2rentContract[number] = rentAvailableInformation(0, address(0x0), 0, rentActiveInformation(address(0x0), 0));
    }

    function rentSeeAvailableNumbers() view external returns (string[] memory) {
        return availableRentNumbers;
    }

    function rentGetInformationOnNumber(string calldata number) view external returns (uint256, uint256) {
        return (number2rentContract[number].price, number2rentContract[number].endTimestamp);
    }

    //Functions for auctions:
    //Start auction for number
    function auctionStart(string number, uint256 nmbrSecondsDuration) {
        require(number2numberInformation[number].owner == msg.sender, "Trying to rent out a number that you don't own");
        require(number2numberInformation[number].isBeeingRentedOrAuctionedOrListed == false, "Number is not available for rent");
        number2numberInformation[number].isBeeingRentedOrAuctionedOrListed = true;
        numbersBeingAuctioned.push(number);
        number2auctionState[number] = auctionStateInformation(address(0x0), 0, block.timestamp +  nmbrSecondsDuration);
    }

    //Bid on an auction:
    function auctionBid(string number, uint256 amount) external {

    }

    //Close auction after end timestamp was passed
    function auctionEnd(string number, uint256 amount) {

    }

    //See available auctions
    function auctionSeeAvailable() view external returns (string[] memory) {
        return numbersBeingAuctioned;
    }

    //Get auction information
    function auctionGetInformation(string calldata number) view external returns (uint256, uint256) {
        return (number2auctionState[number].highestBid, number2auctionState[number].endTimestamp);
    }
}

//contract mortal { <--- Doesn't work because of method visibility
//    address payable contractOwner;
//    constructor() { contractOwner = payable(msg.sender); }
//    function kill() internal { if (msg.sender == contractOwner) selfdestruct(contractOwner); }
//}
//
//contract numberRenting is mortal {
//    address originalOwner;
//    uint256 rentingAvailabilityEndTimestamp; //End timestamp for this contract
//    uint256 rentingPeriodEndTimestamp; //End timestamp for the current rent
//    numberService service;
//    string rentingNumber;
//    uint256 rentPrice;
//
//    constructor(uint256 _nmbrSeconds, string memory _originalOwner, string _rentingNumber, uint256 _rentPrice) mortal() {
//        endTimestamp = block.timestamp + _nmbrSeconds;
//        originalOwner = _originalOwner;
//        rentingNumber = _rentingNumber;
//        rentPrice = _rentPrice;
//    }
//
//    function rentOutNumber() {
//        service.transferNumber(originalOwner, contractOwner, subscribedNumber, 0);
//    }
//
//    function checkEnding() internal returns(uint256) {//Transfer ownership if timestamps allow
//        if(endTimestamp<block.timestamp) {
//            service.transferNumber(originalOwner, contractOwner, subscribedNumber, 0);
//            kill();
//        }
//        return endTimestamp;
//    }
//
//}