package com.example.springboot;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class MarketController {

    @GetMapping("/market")
    public String listAvailableNumbers(Model model) {
        //TODO: replace with real data
        String[] phoneNumbersForSale = {"334444241", "42124214", "52115125", "425235215", "42532552"};
        String[] phoneNumbersForRent = {"1111222333", "999888777", "333444555", "222777888", "19191919"};


        model.addAttribute("phoneNumbersForSale", phoneNumbersForSale);
        model.addAttribute("phoneNumbersForRent", phoneNumbersForRent);


        return "market";
    }

    @PostMapping("/market/phone-number/buy/{number}")
    public String buyNumber(Model model, @PathVariable(value="number") String number) {
        //TODO: replace with real data
        String numberToDelete = model.getAttribute("number").toString();
        String[] availablePhoneNumbers = {"334444241", "42124214", "52115125", "425235215", "42532552"};

        model.addAttribute("numbers", availablePhoneNumbers);

        return "market";
    }

    @PostMapping("/market/phone-number/rent/{number}")
    public String rentNumber(Model model, @PathVariable(value="number") String number) {
        //TODO: replace with real data
        String numberToDelete = model.getAttribute("number").toString();
        String[] availablePhoneNumbers = {"35463346241", "555888899", "999777888666", "222777444888", "999000888777"};

        model.addAttribute("numbers", availablePhoneNumbers);

        return "market";
    }
}
