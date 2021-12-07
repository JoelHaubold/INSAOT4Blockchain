package com.example.springboot;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Controller
public class AuctionController {

	@GetMapping("/auction")
	public String showAuctionInfo(Model model) throws Exception {
		//TODO: replace with real data
		addDataToModel(model);
		model.addAttribute("tab", "home");

		return "auction";
	}

	@GetMapping("/auction/buy")
	public String showAuctionItems(Model model) throws Exception {
		//TODO: replace with real data
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
		//TODO: replace with logic
		addDataToModel(model);
		model.addAttribute("tab", "buy");

		return "auction";
	}

	@PostMapping("/auction/off")
	public String offNumber(Model model,
							 @RequestParam int number,
							 @RequestParam int price,
							 @RequestParam("deadline") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadline
	) throws Exception {
		//TODO: replace with logic
		addDataToModel(model);
		model.addAttribute("tab", "sell");

		return "auction";
	}

	private void addDataToModel(Model model) throws Exception {
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();
		List result = contract.seeOwnedNumbers().send();
		ArrayList<String> myPhoneNumbers = new ArrayList<>();
		if (result.size() >= 1) {
			myPhoneNumbers.addAll((List<String>) result);
			myPhoneNumbers.remove(0);
		}
		AuctionItem[] myBids = {
				new AuctionItem(1112223333, 10, "address1"),
				new AuctionItem(1112223444, 10, "address2"),
				new AuctionItem(1112225555, 10, "address3"),
				new AuctionItem(1112226666, 12, "myAddress"),
		};

		AuctionItem[] auctionItems = {
				new AuctionItem(999888777, 10, "address1"),
				new AuctionItem(888777666, 10, "address2"),
				new AuctionItem(777666555, 10, "address3"),
		};

		model.addAttribute("myPhoneNumbers", myPhoneNumbers);
		model.addAttribute("myBids", myBids);
		model.addAttribute("auctionItems", auctionItems);
		model.addAttribute("myAddress", "myAddress");



	}

	// TODO: remove when have real data
	private class AuctionItem {
		public int phoneNumber;
		public int highestBid;
		public LocalDateTime deadline;
		public String highestBidUserAddress;
		public List<String> competingUserAdresses = new ArrayList<>();

		public AuctionItem(int phoneNumber, int highestBid, String highestBidUserAddress) {
			this.phoneNumber = phoneNumber;
			this.highestBid = highestBid;
			this.deadline = LocalDateTime.now().plusHours((int) ((Math.random() * (30)) + 3)); // some random deadline
			this.highestBidUserAddress = highestBidUserAddress;
			this.competingUserAdresses = Arrays.asList("address1", "address2", "address3", "myAddress"); // to track users to whom we will display their bids
		}
	}
}
