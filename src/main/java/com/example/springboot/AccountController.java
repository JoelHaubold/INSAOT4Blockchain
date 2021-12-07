package com.example.springboot;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.web3j.abi.FunctionReturnDecoder;
import org.web3j.abi.datatypes.Type;
import org.web3j.protocol.core.methods.response.EthGetTransactionReceipt;
import org.web3j.protocol.core.methods.response.Log;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.rlp.RlpDecoder;

import javax.servlet.ServletOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

@Controller
public class AccountController {
	// TODO: this is to mimic the login process, change accordingly

	@GetMapping("/account")
	public String showAccountActions(Model model) {
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
	public String showPhoneNumbers(Model model) throws Exception {
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();
		List result = contract.seeOwnedNumbers().send();
		ArrayList<String> phoneNumbers = new ArrayList<>();
		if (result.size() >= 1) {
			phoneNumbers.addAll((List<String>) result);
			phoneNumbers.remove(0);
		}
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

	@GetMapping("/account/rent-my-number/{number}")
	public String rentMyNumber(Model model, @RequestParam int price, @RequestParam int days) throws Exception {
		//TODO: actually rent the NR
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();
		List result = contract.seeOwnedNumbers().send();
		ArrayList<String> phoneNumbers = new ArrayList<>();
		if (result.size() >= 1) {
			phoneNumbers.addAll((List<String>) result);
			phoneNumbers.remove(0);
		}
		model.addAttribute("tab", "numbers");
		model.addAttribute("phoneNumbers", phoneNumbers);
		return "account";
	}

	@GetMapping("/account/sell-my-number/{number}")
	public String sellMyNumber(Model model, @RequestParam int price) throws Exception {
		//TODO: actually sell the NR

		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();
		List result = contract.seeOwnedNumbers().send();
		ArrayList<String> phoneNumbers = new ArrayList<>();
		if (result.size() >= 1) {
			phoneNumbers.addAll((List<String>) result);
			phoneNumbers.remove(0);
		}
		model.addAttribute("tab", "numbers");
		model.addAttribute("phoneNumbers", phoneNumbers);
		return "account";
	}
}
