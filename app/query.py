from sqlalchemy.orm import Query, query

class CustomQuery(Query):

    def _get_models(self):
        """Returns the query's underlying model classes."""
        if hasattr(query, 'attr'):
          # we are dealing with a subquery
          return [query.attr.target_mapper]
        else:
          return [
            d['expr'].class_
            for d in query.column_descriptions
            if isinstance(d['expr'], Mapper)
          ]

    # Returns the rows on a specific page when split into pages of 'per_page' rows per page.
    def custom_paginate(self, page, per_page=5, return_page_count=False):
        page_count = self.page_count(per_page=per_page)
        page = max(1,min(page,page_count))
        page_content = self.offset((page - 1) * per_page).limit(per_page)
        return page_content, page_count if return_page_count else page_content

    # Returns the amount of pages when split into pages of 'per_page' rows per page.
    def page_count(self, per_page=5):
        return  (lambda n: int(n / per_page) if (n / per_page).is_integer() else int(n / per_page) + 1)(self.count())