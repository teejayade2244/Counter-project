import React from "react"
import { render, screen, fireEvent } from "@testing-library/react"
import App from "./App"


describe("Counter Component", () => {
    test("renders the Counter component", () => {
        render(<App />)
        expect(screen.getByText("Counter")).toBeInTheDocument()
        expect(screen.getByText("Current Count: 0")).toBeInTheDocument()
    })

    test("increments the counter", () => {
        render(<App />)
        const incrementButton = screen.getByText("Increment")
        fireEvent.click(incrementButton)
        expect(screen.getByText("Current Count: 1")).toBeInTheDocument()
    })

    test("decrements the counter", () => {
        render(<App />)
        const decrementButton = screen.getByText("Decrement")
        fireEvent.click(decrementButton)
        expect(screen.getByText("Current Count: -1")).toBeInTheDocument()
    })

    test("resets the counter", () => {
        render(<App />)
        const incrementButton = screen.getByText("Increment")
        const resetButton = screen.getByText("Reset")
        fireEvent.click(incrementButton)
        fireEvent.click(resetButton)
        expect(screen.getByText("Current Count: 0")).toBeInTheDocument()
    })
})
