#
# A slot machine.
#
class SlotMachine < ApplicationRecord
  has_many :slot_machine_symbols

  #
  # Returns a grid of symbols.
  #
  # @return [Array<Array<>>] a grid of symbols.
  #
  def random_grid
    matrix = []

    rows.times do
      matrix << random_row
    end

    matrix
  end

  #
  # Given a matrix of symbols (a list of rows) and a bet, returns the
  # payout.
  #
  # @param [Array<Array<SlotMachineSymbol>>] grid the grid of symbols.
  # @param [<Type>] bet the bet amount.
  #
  # @raise [ArgumentError] if the grid is not a array.
  # @raise [ArgumentError] if bet is not a integer.
  #
  # @return [Integer] the payout.
  #
  def calculate_payout(grid, bet)
    raise ArgumentError, 'Grid is not a array' unless grid.is_a? Array
    raise ArgumentError, 'Bet is not numeric' unless bet.is_a? Integer

    payout = 0
    winnings = winnings(grid, 1)
    bet_multiplier = bet / 50

    winnings.each do |winning|
      payout += winning.value * bet_multiplier
    end

    payout
  end

  private

  #
  # Returns a random row of symbols with the same amount of elements as columns.
  #
  # @return [Array<SlotMachineSymbol>] a row of symbols.
  #
  def random_row
    cols = 3
    row = []

    cols.times do
      row.push(slot_machine_symbols.all.sample)
    end

    row
  end

  #
  # Given a grid of symbols (a list of rows) and the number of lines, returns
  # an array of wins. @see SlotMachineWin TODO: Fix @see
  #
  # @param [Array<Array<SlotMachineSymbol>>] grid the grid of symbols.
  # @param [Integer] n_lines the amount of lines to check.
  #
  # @raise [ArgumentError] if the grid is not a array.
  # @raise [ArgumentError] if n_lines is not a integer.
  # @raise [RangeError] if n_lines is smaller than one.
  #
  # @return [Array<SlotMachineWin>] an array of the winnings.
  #
  def winnings(grid, n_lines)
    raise ArgumentError, 'Grid is not a array' unless grid.is_a? Array
    raise ArgumentError, 'n_lines is not numeric' unless n_lines.is_a? Integer
    raise RangeError, 'n_lines must be greater than 0' unless n_lines.positive?

    # TODO: Add another check if the width and height is correct.

    lines = Line.where(rows: rows, columns: columns)
    output = []

    lines.each do |line|
      symbols_in_line = symbols_in_line(grid, line)

      # Count amount
      symbols_in_line.uniq { |e| e.id }.each do |symbol|
        n = symbols_in_line.select { |s| s.id == symbol.id }.count
        symbol_price = symbol.slot_machine_symbol_paytables.find_by(occurrences: n)
        next if symbol_price.nil?

        output << SlotMachineWin.new(symbol, n, symbol_price.pay)
      end
    end

    output
  end

  #
  # Returns the symbols that are in a specific line.
  #
  # @param [Array<Array<SlotMachineSymbol>>]  grid the grid to extract
  #                                           symols from.
  # @param [Line] line the line.
  #
  # TODO: Add exceptions.
  #
  # @return [Array<SlotMachineSymbol>] an array of symbols
  #
  def symbols_in_line(grid, line)
    output = []

    line.bitmap.split('').each_with_index do |bit, i|
      next unless bit == '1'

      row_index = i / columns
      column_index = i - row_index * columns
      output << grid[row_index][column_index]
    end

    output
  end
end
