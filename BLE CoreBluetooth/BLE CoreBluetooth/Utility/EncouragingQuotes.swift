//
//  EncouragingQuotes.swift
//  BLE CoreBluetooth
//
//  Created by user on 30.11.2021.
//

import Foundation

class EncouragingQuotes {
    
    fileprivate static let quotes: [String] = [
        "We become what we think about",
        "People who are crazy enough to think they can change the world, are the ones who do",
        "Optimism is the one quality more associated with success and happiness than any other",
        "Happiness is not something readymade. It comes from your own actions",
        "All our dreams can come true if we have the courage to pursue them",
        "Success is not final, failure is not fatal: it is the courage to continue that counts",
        "Believe you can and you’re halfway there",
        "I can’t change the direction of the wind, but I can adjust my sails to always reach my destination",
        "It is our attitude at the beginning of a difficult task which, more than anything else, will affect its successful outcome",
        "You are never too old to set another goal or to dream a new dream",
        "We must be willing to let go of the life we planned so as to have the life that is waiting for us",
        "Everything you’ve ever wanted is on the other side of fear",
        "You get what you give",
        "Your life only gets better when you get better",
        "Happiness is not by chance, but by choice",
        "Your life only gets better when you get better",
        "Be the change that you wish to see in the world",
        "If I cannot do great things, I can do small things in a great way.",
        "We generate fears while we sit. We overcome them by action",
        "Today’s accomplishments were yesterday’s impossibilities",
        "Light tomorrow with today",
        "The only limit to our realization of tomorrow will be our doubts of today",
        "The bad news is time flies. The good news is you’re the pilot"
    ]
    
    static fileprivate var previousQuote: String = ""
    
    static func getQuote() -> String {
        if let randomQuote = quotes.randomElement() {
            if randomQuote != previousQuote {
                previousQuote = randomQuote
                return randomQuote
            } else {
                return getQuote()
            }
        }
        return ""
    }
}
