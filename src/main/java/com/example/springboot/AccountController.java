package com.example.springboot;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.view.RedirectView;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

@Controller
public class AccountController {

	@GetMapping("/account")
	public String showAccountActions(Model model) {
		model.addAttribute("tab", "home");

		return "account";
	}

	@GetMapping("/account/details")
	public String showAccountDetails(Model model) throws Exception {
		Singleton singleton = Singleton.getInstance();
		String accountAddress = singleton.getCredentials().getAddress();
		String nickname = "Fat Cat";


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
		System.out.println(result);
		if (result.size() >= 1) {
			phoneNumbers.addAll((List<String>) result);
			phoneNumbers.remove(0);
		}
		model.addAttribute("phoneNumbers", phoneNumbers.stream().filter(n -> !n.startsWith("000_")).collect(Collectors.toList()));
		model.addAttribute("tab", "numbers");

		return "account";
	}

	@GetMapping("/account/balance")
	public String showBalance(Model model) throws Exception {
		//TODO: replace with real data
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();
		BigInteger balance = contract.seeBalance().send();

		model.addAttribute("balance", balance);
		model.addAttribute("tab", "balance");

		return "account";
	}

	@GetMapping("/account/rent-my-number/{number}")
	public String rentMyNumber(Model model, @PathVariable(value="number") String number, @RequestParam int price, @RequestParam int days) throws Exception {
		//TODO: actually rent the NR
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();

		if (contract.rentSeeAvailableNumbers().send().isEmpty()) {
			String randomID = getRandomIdentifier("000");
			contract.buyNumber(randomID, new BigInteger("10")).send();
			contract.rentMakeNumberAvailable(
					randomID,
					new BigInteger("1000000000000000000"),
					new BigInteger("10")
			).send();
		}

		contract.rentMakeNumberAvailable(
				number,
				new BigInteger(String.valueOf(60*60*24*days)),
				new BigInteger(String.valueOf(price))
		).send();

		List result = contract.seeOwnedNumbers().send();
		ArrayList<String> phoneNumbers = new ArrayList<>();
		System.out.println(result);
		if (result.size() >= 1) {
			phoneNumbers.addAll((List<String>) result);
			phoneNumbers.remove(0);
		}
		model.addAttribute("phoneNumbers", phoneNumbers.stream().filter(n -> !n.startsWith("000_")).collect(Collectors.toList()));
		model.addAttribute("tab", "numbers");

		return "account";
	}

	@GetMapping("/account/set-nickname/{number}")
	public String setNickname(Model model, @PathVariable(value="number") String number, @RequestParam String nickname) throws Exception {
		//TODO: actually rent the NR
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();

		contract.buyNickname(nickname, number, BigInteger.valueOf(10)).send();

		List result = contract.seeOwnedNumbers().send();
		ArrayList<String> phoneNumbers = new ArrayList<>();
		System.out.println(result);
		if (result.size() >= 1) {
			phoneNumbers.addAll((List<String>) result);
			phoneNumbers.remove(0);
		}
		model.addAttribute("phoneNumbers", phoneNumbers.stream().filter(n -> !n.startsWith("000_")).collect(Collectors.toList()));
		model.addAttribute("tab", "numbers");

		return "account";
	}

	@GetMapping("/account/sell-my-number/{number}")
	public String sellMyNumber(Model model, @PathVariable(value="number") String number, @RequestParam int price) throws Exception {
		//TODO: actually sell the NR
		Singleton singleton = Singleton.getInstance();
		NumberService contract = singleton.getContract();

		if (contract.seeListedNumbers().send().isEmpty()) {
			System.out.println("Its empty");
			String randomID = getRandomIdentifier("000");
			contract.buyNumber(randomID, new BigInteger("10")).send();
			contract.listNumber(randomID, new BigInteger("1")).send();
		}

		contract.listNumber(number, new BigInteger(String.valueOf(price))).send();
		List result = contract.seeOwnedNumbers().send();
		ArrayList<String> phoneNumbers = new ArrayList<>();
		System.out.println(result);
		if (result.size() >= 1) {
			phoneNumbers.addAll((List<String>) result);
			phoneNumbers.remove(0);
		}
		model.addAttribute("phoneNumbers", phoneNumbers.stream().filter(n -> !n.startsWith("000_")).collect(Collectors.toList()));
		model.addAttribute("tab", "numbers");
		return "account";
	}

	static String getRandomIdentifier(String beginning) throws Exception {
		int leftLimit = 48; // numeral '0'
		int rightLimit = 122; // letter 'z'
		int targetStringLength = 12;
		Random random = new Random();

		String randomID = random.ints(leftLimit, rightLimit + 1)
				.filter(i -> (i <= 57 || i >= 65) && (i <= 90 || i >= 97))
				.limit(targetStringLength)
				.collect(StringBuilder::new, StringBuilder::appendCodePoint, StringBuilder::append)
				.toString();

		System.out.println(randomID);
		return beginning + "_" + randomID;
	}
}
