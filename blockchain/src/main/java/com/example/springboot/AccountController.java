package com.example.springboot;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class AccountController {

	@GetMapping("/account")
	public String showAccountActions(Model model) {
		//TODO: replace with real data

		model.addAttribute("tab", "home");

		return "account";
	}

	@GetMapping("/account/details")
	public String showAccountDetails(Model model) {
		//TODO: replace with real data
		String accountAddress = "000111222";
		String nickname = "FatCat";


		model.addAttribute("accountAddress", accountAddress);
		model.addAttribute("nickname", nickname);
		model.addAttribute("tab", "account");

		return "account";
	}

	@GetMapping("/account/numbers")
	public String showPhoneNumbers(Model model) {
		//TODO: replace with real data
		String[] phoneNumbers = {"11111", "2222222", "3333333"};

		model.addAttribute("phoneNumbers", phoneNumbers);
		model.addAttribute("tab", "numbers");

		return "account";
	}

	@GetMapping("/account/transactions")
	public String showTransactions(Model model) {
		//TODO: replace with real data
		String[] transactions = {"t1", "t2", "t3"};

		model.addAttribute("transactions", transactions);
		model.addAttribute("tab", "transactions");

		return "account";
	}

	@GetMapping("/account/balance")
	public String showBalance(Model model) {
		//TODO: replace with real data
		int balance = 666;

		model.addAttribute("balance", balance);
		model.addAttribute("tab", "balance");

		return "account";
	}

}
