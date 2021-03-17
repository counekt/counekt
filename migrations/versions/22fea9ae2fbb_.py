"""empty message

Revision ID: 22fea9ae2fbb
Revises: aef075f42f0b
Create Date: 2021-03-17 21:51:33.650160

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '22fea9ae2fbb'
down_revision = 'aef075f42f0b'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('group', sa.Column('supergroup_id', sa.Integer(), nullable=True))
    op.create_foreign_key(None, 'group', 'group', ['supergroup_id'], ['id'])
    op.add_column('project', sa.Column('superproject_id', sa.Integer(), nullable=True))
    op.create_foreign_key(None, 'project', 'project', ['superproject_id'], ['id'])
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint(None, 'project', type_='foreignkey')
    op.drop_column('project', 'superproject_id')
    op.drop_constraint(None, 'group', type_='foreignkey')
    op.drop_column('group', 'supergroup_id')
    # ### end Alembic commands ###
