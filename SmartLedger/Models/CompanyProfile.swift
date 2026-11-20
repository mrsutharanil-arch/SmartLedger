import Foundation

public struct CompanyProfile: Codable, Hashable {
    public var companyName: String
    public var legalName: String
    public var businessType: String
    public var taxNumber: String
    public var registrationNumber: String
    public var officialEmail: String
    public var phone: String
    public var website: String
    public var addressLine: String
    public var city: String
    public var country: String
    public var financialYearStart: String
    
    public init(
        companyName: String = "Suthar Anil Arch Tech",
        legalName: String = "Suthar Anil Architecture & Financial Solutions",
        businessType: String = "Technology & Financial Accounting Services",
        taxNumber: String = "TAX-ID: 24AABCS1492Z1",
        registrationNumber: String = "REG-2026-IN-9841",
        officialEmail: String = "mr.sutharanil@gmail.com",
        phone: String = "+91 98765 43210",
        website: String = "https://github.com/mrsutharanil-arch/SmartLedger",
        addressLine: String = "Tech Innovation Boulevard",
        city: String = "Gujarat",
        country: String = "India",
        financialYearStart: String = "April 1"
    ) {
        self.companyName = companyName
        self.legalName = legalName
        self.businessType = businessType
        self.taxNumber = taxNumber
        self.registrationNumber = registrationNumber
        self.officialEmail = officialEmail
        self.phone = phone
        self.website = website
        self.addressLine = addressLine
        self.city = city
        self.country = country
        self.financialYearStart = financialYearStart
    }
}
