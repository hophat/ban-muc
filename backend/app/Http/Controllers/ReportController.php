<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\Purchase;
use App\Models\Expense;
use App\Models\Customer;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ReportController extends Controller
{
    /**
     * Get revenue report by date range
     */
    public function revenue(Request $request)
    {
        $startDate = $request->get('start_date', Carbon::now()->startOfMonth());
        $endDate = $request->get('end_date', Carbon::now()->endOfMonth());

        $dailyRevenue = Sale::selectRaw('DATE(sale_date) as date, SUM(total_amount) as revenue')
            ->where('sale_date', '>=', $startDate)
            ->where('sale_date', '<=', $endDate)
            ->where('payment_status', 'paid')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $totalRevenue = $dailyRevenue->sum('revenue');

        return response()->json([
            'daily_revenue' => $dailyRevenue,
            'total_revenue' => $totalRevenue,
            'period' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
        ]);
    }

    /**
     * Get expense report by date range
     */
    public function expenses(Request $request)
    {
        $startDate = $request->get('start_date', Carbon::now()->startOfMonth());
        $endDate = $request->get('end_date', Carbon::now()->endOfMonth());

        // Daily expenses
        $dailyExpenses = Expense::selectRaw('DATE(expense_date) as date, SUM(amount) as expenses')
            ->where('expense_date', '>=', $startDate)
            ->where('expense_date', '<=', $endDate)
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        // Expenses by type
        $expensesByType = Expense::selectRaw('expense_type, SUM(amount) as total')
            ->where('expense_date', '>=', $startDate)
            ->where('expense_date', '<=', $endDate)
            ->groupBy('expense_type')
            ->orderBy('total', 'desc')
            ->get();

        // Purchase costs
        $purchaseCosts = Purchase::selectRaw('DATE(purchase_date) as date, SUM(total_amount) as costs')
            ->where('purchase_date', '>=', $startDate)
            ->where('purchase_date', '<=', $endDate)
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        $totalExpenses = $dailyExpenses->sum('expenses');
        $totalPurchaseCosts = $purchaseCosts->sum('costs');
        $totalCosts = $totalExpenses + $totalPurchaseCosts;

        return response()->json([
            'daily_expenses' => $dailyExpenses,
            'expenses_by_type' => $expensesByType,
            'purchase_costs' => $purchaseCosts,
            'total_expenses' => $totalExpenses,
            'total_purchase_costs' => $totalPurchaseCosts,
            'total_costs' => $totalCosts,
            'period' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
        ]);
    }

    /**
     * Get profit report
     */
    public function profit(Request $request)
    {
        $startDate = $request->get('start_date', Carbon::now()->startOfMonth());
        $endDate = $request->get('end_date', Carbon::now()->endOfMonth());

        // Revenue (paid sales only)
        $totalRevenue = Sale::where('sale_date', '>=', $startDate)
            ->where('sale_date', '<=', $endDate)
            ->where('payment_status', 'paid')
            ->sum('total_amount');

        // Purchase costs
        $totalPurchaseCosts = Purchase::where('purchase_date', '>=', $startDate)
            ->where('purchase_date', '<=', $endDate)
            ->sum('total_amount');

        // Other expenses
        $totalExpenses = Expense::where('expense_date', '>=', $startDate)
            ->where('expense_date', '<=', $endDate)
            ->sum('amount');

        $totalCosts = $totalPurchaseCosts + $totalExpenses;
        $profit = $totalRevenue - $totalCosts;

        // Daily profit calculation
        $dailyData = [];
        $current = Carbon::parse($startDate);
        $end = Carbon::parse($endDate);

        while ($current <= $end) {
            $date = $current->format('Y-m-d');
            
            $dayRevenue = Sale::whereDate('sale_date', $date)
                ->where('payment_status', 'paid')
                ->sum('total_amount');
                
            $dayPurchaseCosts = Purchase::whereDate('purchase_date', $date)
                ->sum('total_amount');
                
            $dayExpenses = Expense::whereDate('expense_date', $date)
                ->sum('amount');
                
            $dayProfit = $dayRevenue - ($dayPurchaseCosts + $dayExpenses);
            
            $dailyData[] = [
                'date' => $date,
                'revenue' => $dayRevenue,
                'costs' => $dayPurchaseCosts + $dayExpenses,
                'profit' => $dayProfit,
            ];
            
            $current->addDay();
        }

        return response()->json([
            'total_revenue' => $totalRevenue,
            'total_purchase_costs' => $totalPurchaseCosts,
            'total_expenses' => $totalExpenses,
            'total_costs' => $totalCosts,
            'profit' => $profit,
            'daily_data' => $dailyData,
            'period' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
        ]);
    }

    /**
     * Get debt report (unpaid sales)
     */
    public function debts(Request $request)
    {
        $customers = Customer::with(['sales' => function ($query) {
            $query->where('payment_status', 'unpaid');
        }])->get()->map(function ($customer) {
            $unpaidSales = $customer->sales;
            $totalDebt = $unpaidSales->sum('total_amount');
            
            return [
                'customer' => $customer,
                'total_debt' => $totalDebt,
                'unpaid_sales' => $unpaidSales,
                'sales_count' => $unpaidSales->count(),
            ];
        })->filter(function ($item) {
            return $item['total_debt'] > 0;
        })->sortByDesc('total_debt')->values();

        $totalDebt = $customers->sum('total_debt');

        return response()->json([
            'customers_with_debt' => $customers,
            'total_debt' => $totalDebt,
        ]);
    }

    /**
     * Get dashboard summary
     */
    public function dashboard(Request $request)
    {
        $today = Carbon::today();
        $thisMonth = Carbon::now()->startOfMonth();
        
        // Today's stats
        $todayRevenue = Sale::whereDate('sale_date', $today)
            ->where('payment_status', 'paid')
            ->sum('total_amount');
            
        $todayExpenses = Expense::whereDate('expense_date', $today)
            ->sum('amount') + Purchase::whereDate('purchase_date', $today)
            ->sum('total_amount');
            
        // This month's stats
        $monthRevenue = Sale::where('sale_date', '>=', $thisMonth)
            ->where('payment_status', 'paid')
            ->sum('total_amount');
            
        $monthExpenses = Expense::where('expense_date', '>=', $thisMonth)
            ->sum('amount') + Purchase::where('purchase_date', '>=', $thisMonth)
            ->sum('total_amount');
            
        // Total debt
        $totalDebt = Sale::where('payment_status', 'unpaid')
            ->sum('total_amount');
            
        // Recent transactions
        $recentSales = Sale::with(['customer', 'squidType'])
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();
            
        $recentPurchases = Purchase::with(['boat', 'squidType'])
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'today' => [
                'revenue' => $todayRevenue,
                'expenses' => $todayExpenses,
                'profit' => $todayRevenue - $todayExpenses,
            ],
            'this_month' => [
                'revenue' => $monthRevenue,
                'expenses' => $monthExpenses,
                'profit' => $monthRevenue - $monthExpenses,
            ],
            'total_debt' => $totalDebt,
            'recent_sales' => $recentSales,
            'recent_purchases' => $recentPurchases,
        ]);
    }
}
