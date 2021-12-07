package com.example.springboot;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.web3j.protocol.core.methods.response.TransactionReceipt;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

@Controller
public class MarketController {
    private final Pattern pattern = Pattern.compile("-?\\d+(\\.\\d+)?");

    @GetMapping("/market")
    public String listAvailableNumbers(Model model) throws Exception {

        Singleton singleton = Singleton.getInstance();
        NumberService contract = singleton.getContract();

        List phoneNumbersForSale = contract.seeListedNumbers().send();
        List phoneNumbersForRent = contract.rentSeeAvailableNumbers().send();

        ArrayList<String> forSale = new ArrayList<>();
        ArrayList<String> forRent = new ArrayList<>();

        if (phoneNumbersForSale.size() >= 1) {
            forSale.addAll(phoneNumbersForSale);
            forSale.remove(0);
        }
        if (phoneNumbersForRent.size() >= 1) {
            forRent.addAll(phoneNumbersForRent);
            forRent.remove(0);
        }

        model.addAttribute("phoneNumbersForSale", forSale);
        model.addAttribute("phoneNumbersForRent", forRent);


        return "market";
    }

    @PostMapping("/market/phone-number/buy/{number}")
    public String buyNumber(Model model, @PathVariable(value="number") String number) throws Exception {
        if ( ! pattern.matcher(number).matches() ) {
            return "market";
        }

        Singleton singleton = Singleton.getInstance();
        NumberService contract = singleton.getContract();

        List result = contract.seeOwnedNumbers().send();

        if ( result.isEmpty() ) {
            String randomID = AccountController.getRandomIdentifier("000");
            contract.buyNumber(randomID, new BigInteger("10")).send();
        }

        contract.buyNumber(number, contract.seePriceOfListedNumber(number).send()).send();

        return "redirect:/account/numbers";
    }

    @PostMapping("/market/phone-number/buy/my-choice")
    public String buyNumberOfMyChoice(Model model, @RequestParam String number) throws Exception {
        if ( ! pattern.matcher(number).matches() ) {
            return "market";
        }

        Singleton singleton = Singleton.getInstance();
        NumberService contract = singleton.getContract();

        List result = contract.seeOwnedNumbers().send();

        if ( result.isEmpty() ) {
            String randomID = AccountController.getRandomIdentifier("000");
            TransactionReceipt receipt = contract.buyNumber(randomID, new BigInteger("10")).send();
            System.out.println(receipt);
        }


        TransactionReceipt receipt = contract.buyNumber(number, new BigInteger("10")).send();
        System.out.println(receipt);

        return "redirect:/account/numbers";
    }

    @PostMapping("/market/phone-number/rent/{number}")
    public String rentNumber(Model model, @PathVariable(value="number") String number) {
        // TODO

        return "redirect:/account/numbers";
    }

    @PostMapping("/market/phone-number/rent/my-choice")
    public String rentNumberOfMyChoice(Model model, @RequestParam String number) {
        // TODO

        return "market";
    }
}
