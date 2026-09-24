import React, { useEffect, useState } from "react";
import styles from "./Next.module.css";
import { createMatrix } from "../helpers/Helpers";

const Next = (props) => {

    const [next, setNext] = useState(props.next);

    useEffect(() => {
        setNext(props.next);
    }, [props.next]);

    const tetrominos = next?.tetrominos();

    const matrix = tetrominos
        ? createMatrix(tetrominos)
        : "";

    return (
        <div>
            <div className="title">
                <span>Next</span>
            </div>

            <div className={styles.matrix}>
                {matrix}
            </div>
        </div>
    );
};

export default Next;
