import { Token } from "../Main"
import { useEthers, useTokenBalance, useContractCall } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { BalanceMsg } from "../BalanceMsg"
import { ContentMsg } from "../ContentMsg"

import { constants, utils } from "ethers"
import TokenFarm from "../../chain-info/contracts/TokenFarm.json"
import networkMapping from "../../chain-info/deployments/map.json"

export interface UnusedPremiumProps {
    token: Token
}

export const UnusedPremium = ({ token }: UnusedPremiumProps) => {
    // address
    // abi
    // chainId
    const { chainId, account } = useEthers()
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero
    const tokenFarmInterface = new utils.Interface(abi)
    const { image, address, name } = token

    const [premium] =
        useContractCall(
            account &&
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "userUnusedPremium", // Method to be called
                args: [account], // Method arguments - address to be checked for balance
            }
        ) ?? [];

    //console.log("userUnusedPremium:", premium)

    const [usder_side] =
        useContractCall(
            account &&
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "getSide", // Method to be called
                args: [account], // Method arguments - address to be checked for balance
            }
        ) ?? ["side error"];
    console.log("user-side:", Number(usder_side))
    //debugger;

    const formattedTokenBalance: number = premium ? parseFloat(formatUnits(premium, 18)) : 0
    return (<ContentMsg
        label={`premium of your order in the market is`}
        amount={formattedTokenBalance} />)
}
