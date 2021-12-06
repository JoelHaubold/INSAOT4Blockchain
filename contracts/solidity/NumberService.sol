pragma experimental ABIEncoderV2;
pragma solidity ^0.5.2;
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
    struct numberInformation {
        address owner;
        bool isBeingRentedOrAuctionedOrListed; //If this is set true it means the number is already beeing listed/rented/auctioned. Set false when bought/returned/the auction finishes.
    }
    mapping(string=>numberInformation) number2numberInformation;

    // Marketplace
    // Listings
    mapping(string=>uint256) number2listingPrice;
    string[] listedNumbers;
    // Renting
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
    //Auctions
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

    constructor() public {
        numberProvider = msg.sender;
    }

    //Private helper funtion to give a free number to a reveicer
    function receiveNumber(address receiver, string memory number) private {
        number2numberInformation[number] = numberInformation(receiver,false);
        owner2account[receiver].ownedNumbers.push(number);
    }

    //Private helper funtion to transfer a number and mark the pay for the donor
    function transferNumber(address receiver, address donor, string memory number, uint256 pay) internal {
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

    //Private helper function to compare two strings for equality
    function compareStrings(string memory s1, string memory s2) internal pure returns (bool){
        return keccak256(bytes(s1)) == keccak256(bytes(s2));
    }

    // Private helper function to translate bytes into a readable string
    function toString(bytes memory data) internal pure returns(string memory) {
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

    //See if the suspected owner is the owner of the number
    function checkOwner(string calldata number, address suspectedOwner) view external returns (bool) {
        address numberHolder = number2numberInformation[number].owner;
        return suspectedOwner == numberHolder;
    }

    //Return the Owner of the given number
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

    //Return all owned numbers of the caller
    function seeOwnedNumbers() view external returns (string[] memory) {
        return owner2account[msg.sender].ownedNumbers;
    }

    //Return the balance of the caller
    function seeBalance() view external returns (uint256) {
        return owner2account[msg.sender].accountBalance;
    }

    //See all numbers listed for potential buyers
    function seeListedNumbers() view external returns (string[] memory) {
        return listedNumbers;
    }

    //See the price of a listed number
    function seePriceOfListedNumber(string calldata number) view external returns (uint256) {
        return number2listingPrice[number];
    }

    //Transfers to the caller all the money he earned
    function withdrawMoney(address payable sendTo) external {
        uint256 amount = owner2account[msg.sender].accountBalance;
        if(msg.sender == numberProvider) {
            amount += ownerBalance;
        }
        sendTo.transfer(amount);
    }

    //List a number of the caller for the given price for a potential buyer
    function listNumber(string calldata number, uint256 price) external { //Check if number is already listed/auctioned/rented
        require(price>0,"Rent price has to be higher than 0");
        require(number2numberInformation[number].owner==msg.sender, "Trying to list number that you don't own!");
        require(number2numberInformation[number].isBeingRentedOrAuctionedOrListed == false, "Number is not available for listing");
        number2numberInformation[number].isBeingRentedOrAuctionedOrListed = true;
        number2listingPrice[number] = price;
        listedNumbers.push(number);
    }

    //Buy a listed number
    function buyNumber(string calldata number) payable external {
        if(number2numberInformation[number].owner==address(0x0)) {
            require(msg.value == costOfFreeNumber, "Trying to buy a free number, with an inadequate amount of ether");
            receiveNumber(msg.sender, number);
            ownerBalance += costOfFreeNumber;
        } else if(number2listingPrice[number] != 0) {
            require(msg.value == number2listingPrice[number],"Inadequate price for listed number");
            require(number2numberInformation[number].owner != msg.sender, "Can't buy own number");
            address donor = number2numberInformation[number].owner;
            transferNumber(msg.sender, donor, number, msg.value);
            number2listingPrice[number] = 0;
            for (uint i = 0; i < listedNumbers.length; i++) {
                if(compareStrings(listedNumbers[i], number)){
                    listedNumbers[i] = listedNumbers[listedNumbers.length-1];
                    listedNumbers.pop();
                }
            }
            number2numberInformation[number].isBeingRentedOrAuctionedOrListed = false;
        } else {
            require(false, "Number is neither available nor listed by it's owner");
        }

    }

    //Buy a nickname for a number to be displayed if you own that number
    function buyNickname(string calldata nickname, string calldata number) payable external {
        require(msg.value == costOfNickname, "Inadequate amount of ether for nickname");
        owner2account[msg.sender].number2nickname[number] = nickname;
    }

    //Functions for renting:
    //Rent a number that was marked by its owner as rentable for the given number of seconds. Price depends on the rent duration as specifie by the owners
    function rentNumber(string calldata number, uint256 nmbrSeconds) payable external {
        require(number2rentContract[number].price!=0, "This number is not available to rent");
        require((number2rentContract[number].price)*nmbrSeconds+costOfReturnDelay==msg.value, "Inadequate price for renting this number");
        require(number2rentContract[number].currentActiveRent.renter == address(0x0), "This number is already beeing rented");
        require(number2rentContract[number].originalOwner != msg.sender, "Can't rent own number");
        uint256 endTimestamp = nmbrSeconds + block.timestamp;
        require(number2rentContract[number].endTimestamp > endTimestamp, "Trying to rent number for longer than its availability");
        number2rentContract[number].currentActiveRent = rentActiveInformation(msg.sender, endTimestamp);
        transferNumber(msg.sender, number2rentContract[number].originalOwner, number, msg.value-costOfReturnDelay);
        for (uint i = 0; i < availableRentNumbers.length; i++) {
            if(compareStrings(availableRentNumbers[i], number)){
                availableRentNumbers[i] = availableRentNumbers[availableRentNumbers.length-1];
                availableRentNumbers.pop();
            }
        }
    }

    //Makes a number owned by the caller available to rent for the given number of seconds. Renters will be charged the price per second.
    //You have to prepay a fee that is kept if you don't return the rented number on time with rentEndInstance.
    function rentMakeNumberAvailable(string calldata number, uint256 price, uint256 nmbrSeconds) external {
        require(price>0,"Rent price has to be higher than 0");
        require(number2numberInformation[number].owner == msg.sender, "Trying to rent out a number that you don't own");
        require(number2numberInformation[number].isBeingRentedOrAuctionedOrListed == false, "Number is not available for rent");
        number2numberInformation[number].isBeingRentedOrAuctionedOrListed = true;
        availableRentNumbers.push(number);
        number2rentContract[number] = rentAvailableInformation(price, msg.sender, nmbrSeconds + block.timestamp, rentActiveInformation(address(0x0), 0));
    }

    //End the renting of a number if the rent duration elapsed. If returned to late the prepayed fee will be kept
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

    //End the number being available for rent if the prespecified duration elapsed
    function rentEndAvailability(string calldata number) external {
        require(number2rentContract[number].originalOwner != address(0x0), "Number is not listed as rentable");
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
        number2numberInformation[number].isBeingRentedOrAuctionedOrListed = false;
        number2rentContract[number] = rentAvailableInformation(0, address(0x0), 0, rentActiveInformation(address(0x0), 0));
    }

    //Returns all numbers available to rent
    function rentSeeAvailableNumbers() view external returns (string[] memory) {
        return availableRentNumbers;
    }

    //Returns information on a number that can be rent
    function rentGetInformationOnNumber(string calldata number) view external returns (uint256, uint256) {
        return (number2rentContract[number].price, number2rentContract[number].endTimestamp);
    }

    //Functions for auctions:
    //Start auction for number
    function auctionStart(string calldata number, uint256 nmbrSecondsDuration) external {
        require(number2numberInformation[number].owner == msg.sender, "Trying to rent out a number that you don't own");
        require(number2numberInformation[number].isBeingRentedOrAuctionedOrListed == false, "Number is not available for auction");
        number2numberInformation[number].isBeingRentedOrAuctionedOrListed = true;
        numbersBeingAuctioned.push(number);
        number2auctionState[number] = auctionStateInformation(address(0x0), 0, block.timestamp +  nmbrSecondsDuration);
    }

    //Bid on an auction:
    function auctionBid(string calldata number) external payable {
        require(number2auctionState[number].endTimestamp != 0, "Number isn't available to bid on");
        require(number2auctionState[number].highestBid < msg.value, "Bid is not high enough");
        require(number2numberInformation[number].owner != msg.sender, "Can't bid on own number");
        require(block.timestamp < number2auctionState[number].endTimestamp, "Auction is over");
        owner2account[number2auctionState[number].highestBider].accountBalance += number2auctionState[number].highestBid;
        number2auctionState[number].highestBider = msg.sender;
        number2auctionState[number].highestBid = msg.value;
    }

    //Close auction after end timestamp was passed
    function auctionEnd(string calldata number) external {
        require(number2auctionState[number].endTimestamp != 0, "Number isn't in auction");
        require(block.timestamp >= number2auctionState[number].endTimestamp, "Auction isn't over yet");
        transferNumber(number2auctionState[number].highestBider, number2numberInformation[number].owner, number, number2auctionState[number].highestBid);
        for (uint i = 0; i < numbersBeingAuctioned.length; i++) {
            if(compareStrings(numbersBeingAuctioned[i], number)){
                numbersBeingAuctioned[i] = numbersBeingAuctioned[numbersBeingAuctioned.length-1];
                numbersBeingAuctioned.pop();
            }
        }
        number2numberInformation[number].isBeingRentedOrAuctionedOrListed = false;
        number2auctionState[number] = auctionStateInformation(address(0x0),0,0);
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
