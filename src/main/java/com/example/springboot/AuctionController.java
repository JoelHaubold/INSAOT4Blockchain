package com.example.springboot;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class AuctionController {

	@GetMapping("/auction")
	public String showAuction(Model model) {
		//TODO: replace with real data
		model.addAttribute("tab", "home");

		return "auction";
	}
}
