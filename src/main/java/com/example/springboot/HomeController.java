package com.example.springboot;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import javax.servlet.http.HttpServletRequest;

@Controller
public class HomeController {
	String appName = "blockchain";

	@GetMapping("/")
	public String homePage(Model model) {
		model.addAttribute("appName", appName);
		return "home";
	}

	@GetMapping("/search")
	public String homePage(Model model, HttpServletRequest request, RedirectAttributes redir, @RequestParam int number) {
//		TODO: replace with real data
		String owner = "some_owner";

		model.addAttribute("appName", appName);
		redir.addFlashAttribute("owner",owner);


		String referer = request.getHeader("Referer");
		return "redirect:"+ referer;
	}

}
