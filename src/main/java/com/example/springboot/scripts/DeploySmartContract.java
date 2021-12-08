package com.example.springboot.scripts;

import com.example.springboot.NumberService;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.http.HttpService;
import org.web3j.tx.gas.DefaultGasProvider;

public class DeploySmartContract {
    static final String ROOT_DIR = "/home/natalia/.ethereum/alanIsJopa/keystore/";
    static final String SOURCE = "UTC--2021-11-23T09-41-28.990398930Z--399b0e69d8a1a4162fd3a93cd95b26c455c352a9";
    static final String SOURCE_PASSWORD = "alanIsJopa";


    public static void main(String[] args) throws Exception {
        Web3j web = Web3j.build(new HttpService());

        Credentials credentials = WalletUtils.loadCredentials(
                SOURCE_PASSWORD,
                ROOT_DIR + SOURCE
        );

        NumberService contract = NumberService.deploy(
                web,
                credentials,
                DefaultGasProvider.GAS_PRICE,
                DefaultGasProvider.GAS_LIMIT
        ).send();

        System.out.println("Address: " + contract.getContractAddress());
    }
}
