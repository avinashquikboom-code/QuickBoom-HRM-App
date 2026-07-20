// ignore_for_file: non_constant_identifier_names

/// DTOs for the HopKid upstream Sales API.
///
/// SCHEMA RULES (from official HopKid doc):
///   - ALL list fields are real JSON arrays, NEVER omitted, NEVER "[]" strings.
///   - New-record identity keys are sent as null (SalesID, CNID, SalesExchangeID).
///   - Nullable GUIDs auto-fill server-side; send real IDs where available.
///   - CreateInvoiceForm: string "{}" (max 50 chars).
///   - SalesPaymentList minimum: [{PaymentType:"Cash", PaidAmount:<netAmount>}]
///   - SalesAdditionalChargeList: [] when none.
///
/// IMPORTANT – Config Constants:
///   Replace [HopkidSalesConstants.zeroBranchID] and [HopkidSalesConstants.zeroCompanyID]
///   once client provides GetBranchList / GetCustomerList master API values.



// ─────────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────────

class HopkidSalesConstants {
  HopkidSalesConstants._();

  /// Zero-GUID: used as placeholder until master data APIs are integrated.
  static const String zeroGuid = '00000000-0000-0000-0000-000000000000';

  // TODO(client): Replace these once GetBranchList / GetCompanyList APIs are available.
  static const String zeroBranchID = zeroGuid;
  static const String zeroCompanyID = zeroGuid;
  static const String zeroCounterID = zeroGuid;

  /// Walk-in customer GUID (used when no CustomerID is selected).
  static const String walkInCustomerID = zeroGuid;

  /// POS sales type as specified by HopKid schema.
  static const String salesTypePOS = 'POS';

  /// Default payment type per schema.
  static const String paymentTypeCash = 'Cash';

  /// CreateInvoiceForm value per schema (max 50 chars string).
  static const String createInvoiceForm = '{}';

  /// Default AccountLedger value.
  static const String defaultAccountLedger = 'Cash';
}

// ─────────────────────────────────────────────────────────────────────────────
//  Product Line Item
// ─────────────────────────────────────────────────────────────────────────────

/// A single row in SalesProductList / CreditNoteProducts / SalesExchangeProductList.
class HopkidSalesProductItem {
  /// Internal HopKid product GUID — use zero-GUID until product master is available.
  final String ProductID;

  /// Variant GUID — zero-GUID until variant master is available.
  final String VariantID;

  /// Brand GUID — zero-GUID until brand master is available.
  final String BrandID;

  /// Category GUID — zero-GUID until category master is available.
  final String CategoryID;

  /// Employee (Salesman) GUID — session employee HopKid ID.
  final String EmployeeID;

  final double Qty;
  final double Price;

  /// Taxable amount for this line item.
  final double Taxable;

  /// Total amount (Qty × Price, net of discounts).
  final double Total;

  final String BarcodeNo;
  final String BatchNo;
  final String Remark;
  /// Primary row identifier (Int32) required by some tables (e.g. tblSalesExchangeProduct)
  final int VasyRowID;

  final String? ProductCode;
  final String? ProductName;
  final String? Unit;
  final double? Discount;
  final double? TaxPercent;
  final double? TaxAmount;

  /// For SalesExchangeProductList: true = returned (old) item, false = new item.
  final bool? IsOld;

  const HopkidSalesProductItem({
    required this.ProductID,
    required this.VariantID,
    required this.BrandID,
    required this.CategoryID,
    required this.EmployeeID,
    required this.Qty,
    required this.Price,
    required this.Taxable,
    required this.Total,
    this.BarcodeNo = '',
    this.BatchNo = '',
    this.Remark = '',
    this.VasyRowID = 0,
    this.ProductCode,
    this.ProductName,
    this.Unit,
    this.Discount,
    this.TaxPercent,
    this.TaxAmount,
    this.IsOld,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'ProductID': ProductID,
      'VariantID': VariantID,
      'BrandID': BrandID,
      'CategoryID': CategoryID,
      'EmployeeID': EmployeeID,
      'Qty': Qty,
      'Price': Price,
      'Taxable': Taxable,
      'Total': Total,
      'BarcodeNo': BarcodeNo,
      'BatchNo': BatchNo,
      'Remark': Remark,
      'VasyRowID': VasyRowID,
    };
    if (ProductCode != null) m['ProductCode'] = ProductCode;
    if (ProductName != null) m['ProductName'] = ProductName;
    if (Unit != null) m['Unit'] = Unit;
    if (Discount != null) m['Discount'] = Discount;
    if (TaxPercent != null) m['TaxPercent'] = TaxPercent;
    if (TaxAmount != null) m['TaxAmount'] = TaxAmount;
    if (IsOld != null) m['IsOld'] = IsOld;
    return m;
  }

  /// Convenience factory for a minimal walk-in product using zero-GUIDs.
  factory HopkidSalesProductItem.minimal({
    required String salesmanGuid,
    required double qty,
    required double price,
    required double total,
    bool isOld = false,
  }) {
    return HopkidSalesProductItem(
      ProductID: HopkidSalesConstants.zeroGuid,
      VariantID: HopkidSalesConstants.zeroGuid,
      BrandID: HopkidSalesConstants.zeroGuid,
      CategoryID: HopkidSalesConstants.zeroGuid,
      EmployeeID: salesmanGuid,
      Qty: qty,
      Price: price,
      Taxable: total, // no tax split until product master is available
      Total: total,
      Discount: 0.0,
      TaxPercent: 0.0,
      TaxAmount: 0.0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Payment Item
// ─────────────────────────────────────────────────────────────────────────────

class HopkidSalesPaymentItem {
  final String PaymentType;
  final double PaidAmount;

  const HopkidSalesPaymentItem({
    required this.PaymentType,
    required this.PaidAmount,
  });

  Map<String, dynamic> toJson() => {
        'PaymentType': PaymentType,
        'PaidAmount': PaidAmount,
      };

  factory HopkidSalesPaymentItem.cash(double amount) =>
      HopkidSalesPaymentItem(
        PaymentType: HopkidSalesConstants.paymentTypeCash,
        PaidAmount: amount,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  AddSales DTO
// ─────────────────────────────────────────────────────────────────────────────

/// Request body for POST /api/Sales/AddSales
///
/// SalesID is null → SP generates the ID and returns it.
class AddSalesDto {
  /// Always null for new records — SP generates the GUID.
  final String? SalesID = null;

  /// Always "POS" per schema.
  final String SalesType;

  /// CustomerID GUID (use zero-GUID for walk-in).
  final String CustomerID;

  /// AccountLedger identifier.
  final String AccountLedger;

  /// Invoice date in IST ISO-8601 format (e.g. "2026-07-20T08:23:31").
  final String Invoicedate;

  /// Due date in IST ISO-8601 format.
  final String Duedate;

  /// Unique invoice number — must be unique across HopKid company.
  final String InvoiceNo;

  /// Salesman GUID — session employee's HopKid employeeID.
  final String SalesMan;

  /// Same as SalesMan for POS entries.
  final String CreatedBy;

  /// Branch GUID — zero-GUID until GetBranchList master is available.
  final String BranchID;

  /// Company GUID — zero-GUID until GetCompanyList master is available.
  final String CompanyID;

  final double GrossAmount;
  final double TaxableAmount;
  final double TaxAmount;
  final double FinalAmount;
  final double NetAmount;
  final double? Discount;

  /// CreateInvoiceForm: string "{}" max 50 chars per schema.
  final String CreateInvoiceForm;

  /// Real JSON array — NEVER null, NEVER omitted. Causes SQL 'n' blocker if absent.
  final List<HopkidSalesProductItem> SalesProductList;

  /// Real JSON array — minimum 1 item (Cash payment). NEVER null/omitted.
  final List<HopkidSalesPaymentItem> SalesPaymentList;

  /// Real JSON array — empty [] when no additional charges.
  final List<Map<String, dynamic>> SalesAdditionalChargeList;

  AddSalesDto({
    required this.SalesType,
    required this.CustomerID,
    required this.AccountLedger,
    required this.Invoicedate,
    required this.Duedate,
    required this.InvoiceNo,
    required this.SalesMan,
    required this.CreatedBy,
    required this.BranchID,
    required this.CompanyID,
    required this.GrossAmount,
    required this.TaxableAmount,
    required this.TaxAmount,
    required this.FinalAmount,
    required this.NetAmount,
    required this.SalesProductList,
    required this.SalesPaymentList,
    this.Discount,
    this.CreateInvoiceForm = HopkidSalesConstants.createInvoiceForm,
    this.SalesAdditionalChargeList = const [],
  });

  Map<String, dynamic> toJson() => {
        'SalesID': null,
        'SalesType': SalesType,
        'CustomerID': CustomerID,
        'AccountLedger': AccountLedger,
        'Invoicedate': Invoicedate,
        'Duedate': Duedate,
        'InvoiceNo': InvoiceNo,
        'SalesMan': SalesMan,
        'CreatedBy': CreatedBy,
        'BranchID': BranchID,
        'CompanyID': CompanyID,
        'GrossAmount': GrossAmount,
        'TaxableAmount': TaxableAmount,
        'TaxAmount': TaxAmount,
        'FinalAmount': FinalAmount,
        'NetAmount': NetAmount,
        'Discount': Discount ?? 0.0,
        'CreateInvoiceForm': CreateInvoiceForm,
        'SalesProductList': SalesProductList.map((p) => p.toJson()).toList(),
        'SalesPaymentList': SalesPaymentList.map((p) => p.toJson()).toList(),
        'SalesAdditionalChargeList': SalesAdditionalChargeList,
      };

  /// Convenience factory — builds a minimal valid AddSalesDto for a single-product POS sale.
  factory AddSalesDto.minimal({
    required String invoiceNo,
    required String salesmanGuid,
    required double grossAmount,
    required double netAmount,
  }) {
    final now = DateTime.now();
    // IST offset already applied by device (assumes IST device time or UTC+5:30 zone)
    final istNow = now.toIso8601String().replaceFirst('Z', '').split('.').first;

    return AddSalesDto(
      SalesType: HopkidSalesConstants.salesTypePOS,
      CustomerID: HopkidSalesConstants.walkInCustomerID,
      AccountLedger: HopkidSalesConstants.defaultAccountLedger,
      Invoicedate: istNow,
      Duedate: istNow,
      InvoiceNo: invoiceNo,
      SalesMan: salesmanGuid,
      CreatedBy: salesmanGuid,
      BranchID: HopkidSalesConstants.zeroBranchID,
      CompanyID: HopkidSalesConstants.zeroCompanyID,
      GrossAmount: grossAmount,
      TaxableAmount: grossAmount,
      TaxAmount: 0.0,
      FinalAmount: netAmount,
      NetAmount: netAmount,
      Discount: 0.0,
      SalesProductList: [
        HopkidSalesProductItem.minimal(
          salesmanGuid: salesmanGuid,
          qty: 1.0,
          price: grossAmount,
          total: netAmount,
        ),
      ],
      SalesPaymentList: [HopkidSalesPaymentItem.cash(netAmount)],
      SalesAdditionalChargeList: const [],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  UpdateSales DTO
// ─────────────────────────────────────────────────────────────────────────────

/// Request body for POST /api/Sales/UpdateSales
///
/// Same shape as AddSalesDto but SalesID is the stored server GUID.
class UpdateSalesDto {
  /// The GUID returned by AddSales — required for update.
  final String SalesID;

  final String SalesType;
  final String CustomerID;
  final String AccountLedger;
  final String Invoicedate;
  final String Duedate;
  final String InvoiceNo;
  final String SalesMan;
  final String CreatedBy;
  final String BranchID;
  final String CompanyID;
  final double GrossAmount;
  final double TaxableAmount;
  final double TaxAmount;
  final double FinalAmount;
  final double NetAmount;
  final double Discount;
  final String CreateInvoiceForm;
  final List<HopkidSalesProductItem> SalesProductList;
  final List<HopkidSalesPaymentItem> SalesPaymentList;
  final List<Map<String, dynamic>> SalesAdditionalChargeList;

  UpdateSalesDto({
    required this.SalesID,
    required this.SalesType,
    required this.CustomerID,
    required this.AccountLedger,
    required this.Invoicedate,
    required this.Duedate,
    required this.InvoiceNo,
    required this.SalesMan,
    required this.CreatedBy,
    required this.BranchID,
    required this.CompanyID,
    required this.GrossAmount,
    required this.TaxableAmount,
    required this.TaxAmount,
    required this.FinalAmount,
    required this.NetAmount,
    this.Discount = 0.0,
    this.CreateInvoiceForm = HopkidSalesConstants.createInvoiceForm,
    required this.SalesProductList,
    required this.SalesPaymentList,
    this.SalesAdditionalChargeList = const [],
  });

  Map<String, dynamic> toJson() => {
        'SalesID': SalesID,
        'SalesType': SalesType,
        'CustomerID': CustomerID,
        'AccountLedger': AccountLedger,
        'Invoicedate': Invoicedate,
        'Duedate': Duedate,
        'InvoiceNo': InvoiceNo,
        'SalesMan': SalesMan,
        'CreatedBy': CreatedBy,
        'BranchID': BranchID,
        'CompanyID': CompanyID,
        'GrossAmount': GrossAmount,
        'TaxableAmount': TaxableAmount,
        'TaxAmount': TaxAmount,
        'FinalAmount': FinalAmount,
        'NetAmount': NetAmount,
        'Discount': Discount,
        'CreateInvoiceForm': CreateInvoiceForm,
        'SalesProductList': SalesProductList.map((p) => p.toJson()).toList(),
        'SalesPaymentList': SalesPaymentList.map((p) => p.toJson()).toList(),
        'SalesAdditionalChargeList': SalesAdditionalChargeList,
      };

  /// Convenience factory — rebuild from an AddSalesDto + the stored SalesID.
  factory UpdateSalesDto.fromAdd(AddSalesDto add, String salesID) {
    return UpdateSalesDto(
      SalesID: salesID,
      SalesType: add.SalesType,
      CustomerID: add.CustomerID,
      AccountLedger: add.AccountLedger,
      Invoicedate: add.Invoicedate,
      Duedate: add.Duedate,
      InvoiceNo: add.InvoiceNo,
      SalesMan: add.SalesMan,
      CreatedBy: add.CreatedBy,
      BranchID: add.BranchID,
      CompanyID: add.CompanyID,
      GrossAmount: add.GrossAmount,
      TaxableAmount: add.TaxableAmount,
      TaxAmount: add.TaxAmount,
      FinalAmount: add.FinalAmount,
      NetAmount: add.NetAmount,
      Discount: add.Discount ?? 0.0,
      CreateInvoiceForm: add.CreateInvoiceForm,
      SalesProductList: add.SalesProductList,
      SalesPaymentList: add.SalesPaymentList,
      SalesAdditionalChargeList: add.SalesAdditionalChargeList,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AddCreditNote DTO
// ─────────────────────────────────────────────────────────────────────────────

/// Request body for POST /api/Sales/AddCreditNote
class AddCreditNoteDto {
  /// Always null for new records — SP generates the CNID.
  final String? CNID = null;

  /// The SalesID of the original sale being credited.
  final String SalesID;

  /// Unique credit note number (e.g. "CN-INV-001").
  final String CNNo;

  /// Amount being credited — must be > 0.
  final double CNAmount;

  /// Salesman GUID — session employee's HopKid employeeID.
  final String Salesman;

  final String BranchID;
  final String CompanyID;
  final String CounterID;

  /// Products being returned — real JSON array, NEVER null.
  final List<HopkidSalesProductItem> CreditNoteProducts;

  AddCreditNoteDto({
    required this.SalesID,
    required this.CNNo,
    required this.CNAmount,
    required this.Salesman,
    required this.CreditNoteProducts,
    this.BranchID = HopkidSalesConstants.zeroBranchID,
    this.CompanyID = HopkidSalesConstants.zeroCompanyID,
    this.CounterID = HopkidSalesConstants.zeroCounterID,
  });

  Map<String, dynamic> toJson() => {
        'CNID': null,
        'SalesID': SalesID,
        'CNNo': CNNo,
        'CNAmount': CNAmount,
        'Salesman': Salesman,
        'BranchID': BranchID,
        'CompanyID': CompanyID,
        'CounterID': CounterID,
        'CreditNoteProducts': CreditNoteProducts.map((p) => p.toJson()).toList(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
//  AddSalesExchange DTO
// ─────────────────────────────────────────────────────────────────────────────

/// Request body for POST /api/Sales/AddSalesExchange
class AddSalesExchangeDto {
  /// Always null for new records — SP generates the SalesExchangeID.
  final String? SalesExchangeID = null;

  /// The SalesID of the original sale being exchanged.
  final String SalesID;

  /// Unique exchange invoice number.
  final String ExchangeInvoiceNo;

  final String BranchID;
  final String CompanyID;

  /// Product list with IsOld flag:
  ///   IsOld = true  → returned / old item going back to store
  ///   IsOld = false → new item being purchased in exchange
  ///
  /// Real JSON array — NEVER null/omitted.
  final List<HopkidSalesProductItem> SalesExchangeProductList;

  AddSalesExchangeDto({
    required this.SalesID,
    required this.ExchangeInvoiceNo,
    required this.SalesExchangeProductList,
    this.BranchID = HopkidSalesConstants.zeroBranchID,
    this.CompanyID = HopkidSalesConstants.zeroCompanyID,
  });

  Map<String, dynamic> toJson() => {
        'SalesExchangeID': null,
        'SalesID': SalesID,
        'ExchangeInvoiceNo': ExchangeInvoiceNo,
        'BranchID': BranchID,
        'CompanyID': CompanyID,
        'SalesExchangeProductList':
            SalesExchangeProductList.map((p) => p.toJson()).toList(),
      };
}
