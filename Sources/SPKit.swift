//
//  File.swift
//  
//
//  Created by Bee on 2021/1/7.
//

import Foundation
//import SPFoundationCategory
//import SPUIKitCategory

open class APP {
    // MARK: Version
    /// Current Version String.
    public static let VERSION: String = {
        if let dic = Bundle.main.infoDictionary, let v = dic["CFBundleShortVersionString"] as? String {
            return v
        }
        return "1.0.0"
    }()
    public static let STORED_VERSION_KEY = "APP_STORED_VERSION"
    public static var STORED_VERSION: String  {
        if let version = UserDefaults.standard.string(forKey: STORED_VERSION_KEY) {
            return version
        }
        UserDefaults.standard.set(VERSION, forKey: STORED_VERSION_KEY)
        return VERSION
    }
    public static func store(version: String) {
        UserDefaults.standard.set(version, forKey: STORED_VERSION_KEY)
    }
    
    
}

// 在主线程执行
public final class OnForeground {
    /**
     * Usable:
     *  OnForeground {
     *      statements...
     *  }
     */
    @discardableResult
    init?(code: @escaping () -> Void) {
        DispatchQueue.main.async(execute: code)
        return nil
    }
}

// 在全局线程执行
public final class OnBackground {
    /**
     * Usable:
     *  OnBackground {
     *      statements...
     *  }
     */
    @discardableResult
    init?(code: @escaping () -> Void) {
        DispatchQueue.global().async(execute: code)
        return nil
    }
    
    /**
     * Usable:
     *  OnBackground(.background) {
     *      statements...
     *  }
     */
    @discardableResult
    init?(_ qos: DispatchQoS.QoSClass, code: @escaping () -> Void) {
        DispatchQueue.global(qos: qos).async(execute: code)
        return nil
    }
}

/*
 
===============================================================================================================
|     Operator     |            Description            |    Associativity    |        Precedence group        |
+==================+===================================+=====================+================================+
|        <<        |  Bitwise left shift               |       None          |     BitwiseShiftPrecedence     |
|        >>        |  Bitwise right shift              |       None          |     BitwiseShiftPrecedence     |
+------------------+-----------------------------------+---------------------+--------------------------------+
|         *        |  Multiply                         |  Left associative   |    MultiplicationPrecedence    |
|         /        |  Divide                           |  Left associative   |    MultiplicationPrecedence    |
|         %        |  Remainder                        |  Left associative   |    MultiplicationPrecedence    |
|        &*        |  Multiply, ignoring overflow      |  Left associative   |    MultiplicationPrecedence    |
|         &        |  Bitwise AND                      |  Left associative   |    MultiplicationPrecedence    |
+------------------+-----------------------------------+---------------------+--------------------------------+
|         +        |  Add                              |  Left associative   |       AdditionPrecedence       |
|         -        |  Subtract                         |  Left associative   |       AdditionPrecedence       |
|        &+        |  Add with overflow                |  Left associative   |       AdditionPrecedence       |
|        &-        |  Subtract with overflow           |  Left associative   |       AdditionPrecedence       |
|         |        |  Bitwise OR                       |  Left associative   |       AdditionPrecedence       |
|         ^        |  Bitwise XOR                      |  Left associative   |       AdditionPrecedence       |
+------------------+-----------------------------------+---------------------+--------------------------------+
|        ..<       |  Half-open range                  |       None          |    RangeFormationPrecedence    |
|        ...       |  Closed range                     |       None          |    RangeFormationPrecedence    |
+------------------+-----------------------------------+---------------------+--------------------------------+
|        is        |  Type check                       |  Left associative   |       CastingPrecedence        |
| as, as?, and as! |  Type cast                        |  Left associative   |       CastingPrecedence        |
+------------------+-----------------------------------+---------------------+--------------------------------+
|        ??        |  Nil coalescing                   |  Right associative  |    NilCoalescingPrecedence     |
+------------------+-----------------------------------+---------------------+--------------------------------+
|         <        |  Less than                        |       None          |      ComparisonPrecedence      |
|        <=        |  Less than or equal               |       None          |      ComparisonPrecedence      |
|         >        |  Greater than                     |       None          |      ComparisonPrecedence      |
|        >=        |  Greater than or equal            |       None          |      ComparisonPrecedence      |
|        ==        |  Equal                            |       None          |      ComparisonPrecedence      |
|        !=        |  Not equal                        |       None          |      ComparisonPrecedence      |
|        ===       |  Identical                        |       None          |      ComparisonPrecedence      |
|        !==       |  Not identical                    |       None          |      ComparisonPrecedence      |
|        ~=        |  Pattern match                    |       None          |      ComparisonPrecedence      |
|        .==       |  Pointwise equal                  |       None          |      ComparisonPrecedence      |
|        .!=       |  Pointwise not equal              |       None          |      ComparisonPrecedence      |
|        .<        |  Pointwise less than              |       None          |      ComparisonPrecedence      |
|        .<=       |  Pointwise less than or equal     |       None          |      ComparisonPrecedence      |
|        .>        |  Pointwise greater than           |       None          |      ComparisonPrecedence      |
|        .>=       |  Pointwise greater than or equal  |       None          |      ComparisonPrecedence      |
+------------------+-----------------------------------+---------------------+--------------------------------+
|        &&        |  Logical AND                      |  Left associative   |  LogicalConjunctionPrecedence  |
|        ||        |  Logical OR                       |  Left associative   |  LogicalDisjunctionPrecedence  |
+------------------+-----------------------------------+---------------------+--------------------------------+
|        ?:        |  Ternary conditional              |  Right associative  |       TernaryPrecedence        |
+------------------+-----------------------------------+---------------------+--------------------------------+
|         =        |  Assign                           |  Right associative  |      AssignmentPrecedence      |
|        *=        |  Multiply and assign              |  Right associative  |      AssignmentPrecedence      |
|        /=        |  Divide and assign                |  Right associative  |      AssignmentPrecedence      |
|        %=        |  Remainder and assign             |  Right associative  |      AssignmentPrecedence      |
|        +=        |  Add and assign                   |  Right associative  |      AssignmentPrecedence      |
|        -=        |  Subtract and assign              |  Right associative  |      AssignmentPrecedence      |
|        <<=       |  Left bit shift and assign        |  Right associative  |      AssignmentPrecedence      |
|        >>=       |  Right bit shift and assign       |  Right associative  |      AssignmentPrecedence      |
|        &=        |  Bitwise AND and assign           |  Right associative  |      AssignmentPrecedence      |
|        |=        |  Bitwise OR and assign            |  Right associative  |      AssignmentPrecedence      |
|        ^=        |  Bitwise XOR and assign           |  Right associative  |      AssignmentPrecedence      |
+------------------+-----------------------------------+---------------------+--------------------------------+
 
*/
