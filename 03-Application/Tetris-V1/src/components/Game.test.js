import React from "react";
import { render, screen } from "@testing-library/react";
import Game from "./Game";

// Mock child components.
// Game.test.js should test Game independently.
jest.mock("./Next.js", () => {
    return function MockNext() {
        return <div data-testid="next-component">Next</div>;
    };
});

jest.mock("./Score.js", () => {
    return function MockScore() {
        return <div data-testid="score-component">Score</div>;
    };
});

jest.mock("./Level.js", () => {
    return function MockLevel() {
        return <div data-testid="level-component">Level</div>;
    };
});

// Mock helper functions used by Game
jest.mock("../helpers/Helpers", () => ({
    createMatrix: jest.fn(() => null)
}));

describe("Game component", () => {

    const createTetrisMock = () => {

        const state = {
            isStarted: () => false,
            isRunning: () => false,
            visibleMatrix: () => [],
            nextPiece: () => null,
            isGameOver: () => false,
            score: () => 0,
            level: () => 1
        };

        return {
            state,
            onStateChange: jest.fn(),
            start: jest.fn(),
            pause: jest.fn(),
            resume: jest.fn()
        };
    };

    test("Game component renders without crashing", () => {

        const tetris = createTetrisMock();

        render(<Game tetris={tetris} />);

        expect(screen.getByText("React Tetris")).toBeInTheDocument();
        expect(screen.getByTestId("next-component")).toBeInTheDocument();
        expect(screen.getByTestId("score-component")).toBeInTheDocument();
        expect(screen.getByTestId("level-component")).toBeInTheDocument();
    });

    test("New Game button is rendered", () => {

        const tetris = createTetrisMock();

        render(<Game tetris={tetris} />);

        const button = screen.getByRole("button", {
            name: /new game/i
        });

        expect(button).toBeInTheDocument();
    });
});
