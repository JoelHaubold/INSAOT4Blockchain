package com.example.springboot;

import org.jetbrains.annotations.NotNull;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.math.BigInteger;
import java.util.List;
import java.util.Random;
import java.util.regex.Pattern;

@Controller
public class MarketController {
    // TODO: this is to mimic the login process, change accordingly

    private final Pattern pattern = Pattern.compile("-?\\d+(\\.\\d+)?");

    @GetMapping("/market")
    public String listAvailableNumbers(Model model) throws Exception {

        Singleton singleton = Singleton.getInstance();
        NumberService contract = singleton.getContract();
        List phoneNumbersForSale = contract.seeListedNumbers().send();
        List phoneNumbersForRent = contract.rentSeeAvailableNumbers().send();

        model.addAttribute("phoneNumbersForSale", phoneNumbersForSale);
        model.addAttribute("phoneNumbersForRent", phoneNumbersForRent);


        return "market";
    }

    @PostMapping("/market/phone-number/buy/{number}")
    public String buyNumber(Model model, @PathVariable(value="number") String number) throws Exception {
        return getNumber(number);
    }

    @PostMapping("/market/phone-number/buy/my-choice")
    public String buyNumberOfMyChoice(Model model, @RequestParam String number) throws Exception {
        return getNumber(number);
    }

    @NotNull
    private String getNumber(String number) throws Exception {
        if ( ! pattern.matcher(number).matches() ) {
            return "market";
        }

        Singleton singleton = Singleton.getInstance();
        NumberService contract = singleton.getContract();

        List result = contract.seeOwnedNumbers().send();

        if ( result.isEmpty() ) {
            int leftLimit = 48; // numeral '0'
            int rightLimit = 122; // letter 'z'
            int targetStringLength = 12;
            Random random = new Random();

            String randomID = random.ints(leftLimit, rightLimit + 1)
                    .filter(i -> (i <= 57 || i >= 65) && (i <= 90 || i >= 97))
                    .limit(targetStringLength)
                    .collect(StringBuilder::new, StringBuilder::appendCodePoint, StringBuilder::append)
                    .toString();
            System.out.println("Its empty, creating first number with id " + randomID);
            contract.buyNumber("FBI_" + randomID, new BigInteger("10")).send();
        }


        contract.buyNumber(number, new BigInteger("10")).send();

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
