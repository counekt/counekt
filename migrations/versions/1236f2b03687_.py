"""empty message

Revision ID: 1236f2b03687
Revises: 56599ba2ec27
Create Date: 2023-12-07 00:16:11.386406

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '1236f2b03687'
down_revision = '56599ba2ec27'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('dividend_token_amount',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('amount', sa.Numeric(precision=78), nullable=True),
    sa.Column('token_id', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['token_id'], ['token.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('bank_token_amount',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('amount', sa.Numeric(precision=78), nullable=True),
    sa.Column('bank_id', sa.Integer(), nullable=True),
    sa.Column('token_id', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['bank_id'], ['bank.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['token_id'], ['token.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.drop_table('token_amount')
    with op.batch_alter_table('dividend', schema=None) as batch_op:
        batch_op.add_column(sa.Column('token_amount_id', sa.Integer(), nullable=True))
        batch_op.add_column(sa.Column('token_residual_id', sa.Integer(), nullable=True))
        batch_op.drop_column('value')
        batch_op.drop_column('token_address')
        batch_op.drop_column('residual')

    with op.batch_alter_table('dividend_claim', schema=None) as batch_op:
        batch_op.add_column(sa.Column('token_amount_id', sa.Integer(), nullable=True))
        batch_op.drop_column('value')

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('dividend_claim', schema=None) as batch_op:
        batch_op.add_column(sa.Column('value', sa.INTEGER(), autoincrement=False, nullable=True))
        batch_op.drop_column('token_amount_id')

    with op.batch_alter_table('dividend', schema=None) as batch_op:
        batch_op.add_column(sa.Column('residual', sa.INTEGER(), autoincrement=False, nullable=True))
        batch_op.add_column(sa.Column('token_address', sa.VARCHAR(length=42), autoincrement=False, nullable=True))
        batch_op.add_column(sa.Column('value', sa.INTEGER(), autoincrement=False, nullable=True))
        batch_op.drop_column('token_residual_id')
        batch_op.drop_column('token_amount_id')

    op.create_table('token_amount',
    sa.Column('id', sa.INTEGER(), autoincrement=True, nullable=False),
    sa.Column('bank_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('token_id', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('amount', sa.NUMERIC(precision=78, scale=0), autoincrement=False, nullable=True),
    sa.ForeignKeyConstraint(['bank_id'], ['bank.id'], name='token_amount_bank_id_fkey', ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['token_id'], ['token.id'], name='token_amount_token_id_fkey', ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name='token_amount_pkey')
    )
    op.drop_table('bank_token_amount')
    op.drop_table('dividend_token_amount')
    # ### end Alembic commands ###
