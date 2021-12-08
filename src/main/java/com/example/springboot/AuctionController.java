package com.example.springboot;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.web3j.tuples.generated.Tuple2;

import java.math.BigInteger;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Controller
public class AuctionController {

	@GetMapping("/auction")
	public String showAuctionInfo(Model model) throws Exception {
		addDataToModel(model);
		model.addAttribute("tab", "home");

		return "auction";
	}

	@GetMapping("/auction/buy")
	public String showAuctionItems(Model model) throws Exception {
		addDataToModel(model);
		model.addAttribute("tab", "buy");

		return "auction";
	}

	@GetMapping("/auction/sell")
	public String showAuctionOff(Model model) throws Exception {
		//TODO: replace with real data
		addDataToModel(model);
		model.addAttribute("tab", "sell");

		return "auction";
	}

	@PostMapping("/auction/bid/{number}")
	public String bid(Model model,
							 @PathVariable int number,
							 @RequestParam int bid) throws Exception {
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();

		contract.auctionBid(String.valueOf(number), new BigInteger(String.valueOf(bid))).send();

		addDataToModel(model);
		model.addAttribute("tab", "buy");

		return "auction";
	}

	@PostMapping("/auction/off")
	public String offNumber(Model model,
							 @RequestParam String number,
							 @RequestParam int price,
							 @RequestParam("deadline") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadline
	) throws Exception {
		//TODO: replace with logic
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();
		long duration = ChronoUnit.SECONDS.between(LocalDateTime.now(), deadline);

		if (contract.auctionSeeAvailable().send().isEmpty()) {
			String randomID = AccountController.getRandomIdentifier("000");
			contract.buyNumber(randomID, new BigInteger("10")).send();
			contract.auctionStart(randomID, new BigInteger("100000")).send();
		}

		contract.auctionStart(number, BigInteger.valueOf(duration)).send();
		addDataToModel(model);
		model.addAttribute("tab", "sell");

		return "auction";
	}

	private void addDataToModel(Model model) throws Exception {
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();

//		TODO: replace getNumbersAvailableForSaleOrRentOrAuction
		List result = contract.seeOwnedNumbers().send();
		ArrayList<String> myPhoneNumbers = new ArrayList<>();
		if (result.size() >= 1) {
			myPhoneNumbers.addAll((List<String>) result);
			myPhoneNumbers.remove(0);
		}

		List<AuctionItem> auctionItems = new ArrayList<>();
		List available = contract.auctionSeeAvailable().send();

		if (available.size() >= 1) {
			available.remove(0);
		}

		System.out.println(available);

		for (Object number : available) {
			String numberAsString = number.toString();
			// First value is highest bid, second is timestamp
			Tuple2<BigInteger, BigInteger> value = contract.auctionGetInformation(numberAsString).send();
			auctionItems.add(new AuctionItem(numberAsString, value.getValue1(), LocalDateTime.ofEpochSecond(value.getValue2().intValue(), 0, ZoneOffset.UTC)));
		}

		model.addAttribute("myPhoneNumbers", myPhoneNumbers.stream().filter(n -> !n.startsWith("000_")).collect(Collectors.toList()));
		model.addAttribute("auctionItems", auctionItems);
		model.addAttribute("myAddress", "myAddress");
	}

	// TODO: remove when have real data
	private class AuctionItem {
		public String phoneNumber;
		public BigInteger highestBid;
		public LocalDateTime deadline;
		public String highestBidUserAddress;
		public List<String> competingUserAdresses = new ArrayList<>();

		public AuctionItem(String phoneNumber, BigInteger highestBid, LocalDateTime deadline) {
			this.phoneNumber = phoneNumber;
			this.highestBid = highestBid;
			this.deadline = deadline; // some random deadline
			this.highestBidUserAddress = highestBidUserAddress;
			this.competingUserAdresses = Arrays.asList("address1", "address2", "address3", "myAddress"); // to track users to whom we will display their bids
		}
	}
}
