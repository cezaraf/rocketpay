defmodule Rocketpay.Accounts.Transaction do
  alias Ecto.Multi

  alias Rocketpay.Accounts.Operation
  alias Rocketpay.Accounts.Transaction.Response, as: TransactionResponse


  alias Rocketpay.Repo

  def call(%{"from" => from, "to" => to, "value" => value}) do
    withdraw_params = build_params(from, value)
    deposit_params = build_params(to, value)

    Multi.new()
    |> Multi.merge(fn _ -> Operation.call(withdraw_params, :withdraw) end)
    |> Multi.merge(fn _ -> Operation.call(deposit_params, :deposit) end)
    |> run_transaction()
  end

  defp build_params(id, value), do: %{"id" => id, "value" => value}

  defp run_transaction(multi) do
    case Repo.transaction(multi) do
      {:error, _, reason, _} -> {:error, reason}
      {:ok, result} -> {:ok, TransactionResponse.build(result.deposit, result.withdraw)}
    end
  end
end
