//
//  PlenConnectionError.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/18.
//  Copyright © 2016年 PLEN Project Company. All rights reserved.
//

import Foundation

protocol PlenConnectionErrorType: ErrorType {
}

enum PlenConnectionError: PlenConnectionErrorType {
    case CentralManagerNotPoweredOn
}