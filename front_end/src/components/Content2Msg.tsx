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

interface Content2MsgProps {
    label: string

}

export const Content2Msg = ({ label }: Content2MsgProps) => {
    const classes = useStyles()

    return (
        <div className={classes.container}>
            <div>{label}</div>
        </div>
    )
}
