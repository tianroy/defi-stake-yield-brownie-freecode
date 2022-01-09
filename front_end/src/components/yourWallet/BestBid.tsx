import { Token } from "../Main"
import { useEthers, useTokenBalance, useContractCall } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { Content2Msg } from "../Content2Msg"


import { constants, utils } from "ethers"
import TokenFarm from "../../chain-info/contracts/TokenFarm.json"
import networkMapping from "../../chain-info/deployments/map.json"
import { EthPrice } from "./EthPrice"

export interface BestBidProps {
    token: Token
}

export const BestBid = ({ token }: BestBidProps) => {
    const { chainId } = useEthers()
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero
    const tokenFarmInterface = new utils.Interface(abi)

    const [bestBid] =
        useContractCall(
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "getBid", // Method to be called
                args: [], // Method arguments - address to be checked for balance
            }
        ) ?? [];

    const [ETHPrice] =
        useContractCall(
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "getETH", // Method to be called
                args: [], // Method arguments - address to be checked for balance
            }
        ) ?? [];

    const [secondsToExpiry] =
        useContractCall(
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "SecondToExpiry", // Method to be called
                args: [], // Method arguments - address to be checked for balance
            }
        ) ?? [];
    // console.log("secondsToExpiry=:", secondsToExpiry)

    // const formattedTokenBalance: number = bestBid ? parseFloat(formatUnits(bestBid, 18)) : 0
    return (<Content2Msg
        label={`年化收益率` + (bestBid / ETHPrice * 100 * 31536000 / secondsToExpiry).toFixed(2)
            + `% 收益率` + (bestBid / ETHPrice * 100).toFixed(2) + `%`} />)
}
