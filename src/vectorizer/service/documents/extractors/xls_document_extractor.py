class XlsDocumentExtractor:
    def extract(self, content: bytes) -> str:
        import xlrd

        workbook = xlrd.open_workbook(file_contents=content)
        return "\n".join(
            " | ".join(str(value) for value in sheet.row_values(row))
            for sheet in workbook.sheets()
            for row in range(sheet.nrows)
        )
