import { makeStyles } from "@material-ui/core"

const useStyles = makeStyles(theme => ({
    container: {
        display: "inline-grid",
        gridTemplateColumns: "auto auto auto",
        gap: theme.spacing(1),
        alignItems: "center",
        fontWeight: 700
    },
    amount: {
        fontWeight: 700
    }
}))

interface ContentMsgProps {
    label: string
    amount: number
}

export const ContentMsg = ({ label, amount }: ContentMsgProps) => {
    const classes = useStyles()

    return (
        <div className={classes.container}>
            <div>{label}</div>
            <div className={classes.amount}>{amount}</div>
        </div>
    )
}
