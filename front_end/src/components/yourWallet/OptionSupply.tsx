import { Token } from "../Main"
import { useEthers, useTokenBalance, useContractCall } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { Content2Msg } from "../Content2Msg"


import { constants, utils } from "ethers"
import TokenFarm from "../../chain-info/contracts/TokenFarm.json"
import networkMapping from "../../chain-info/deployments/map.json"

export interface OptionSupplyProps {
    token: Token
}

export const OptionSupply = ({ token }: OptionSupplyProps) => {
    const { chainId, account } = useEthers()
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero
    const tokenFarmInterface = new utils.Interface(abi)
    const { image, address, name } = token

    const [supply] =
        useContractCall(
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "getSupply", // Method to be called
                args: [], // Method arguments - address to be checked for balance
            }
        ) ?? [];
    //console.log("supply:", supply / 1e18)

    return (<Content2Msg
        label={`剩余可购` + (supply / 1e18).toFixed(1) + 'USDx'} />)
}
