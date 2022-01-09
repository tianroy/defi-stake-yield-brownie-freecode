import { useEffect, useState } from "react"
import { useEthers, useContractFunction } from "@usedapp/core"
import { constants, utils } from "ethers"
import TokenFarm from "../chain-info/contracts/TokenFarm.json"
import { Contract } from "@ethersproject/contracts"
import networkMapping from "../chain-info/deployments/map.json"

export const usePlaceBid = (amount: number, premium: number) => {

    const { chainId } = useEthers()
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero
    const tokenFarmInterface = new utils.Interface(abi)
    const tokenFarmContract = new Contract(tokenFarmAddress, tokenFarmInterface)

    const { send: PlaceBidSend, state: mystate } =
        useContractFunction(tokenFarmContract, "placeBid", {
            transactionName: 'Place bid'
        })
    const PlaceBid = () => { PlaceBidSend(utils.parseEther(amount.toString()), utils.parseEther(premium.toString())) }
    console.log(amount)

    //debugger;
    return { PlaceBid, mystate }
}

