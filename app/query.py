from flask_sqlalchemy import BaseQuery
from sqlalchemy import func

class CustomQuery(BaseQuery):

    # Returns the rows on a specific page when split into pages of 'per_page' rows per page.
    def custom_paginate(self, page, per_page=5, return_page_count=False):
        page_count = self.page_count(per_page=per_page)
        page = max(1,min(page,page_count))
        page_content = self.offset((page - 1) * per_page).limit(per_page)
        return (page_content, page_count) if return_page_count else page_content

    # Returns the amount of pages when split into pages of 'per_page' rows per page.
    def page_count(self, per_page=5):
        return  (lambda x,X : X//x if X%x == 0 else X//x + 1)(per_page, self.count())