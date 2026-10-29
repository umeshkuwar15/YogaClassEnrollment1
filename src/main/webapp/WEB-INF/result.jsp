<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%!
private String escapeHtml(String value) {
    if (value == null) return "";
    return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#x27;");
}
%>
<%
String message = null;
boolean saved = false;
boolean isPost = "POST".equalsIgnoreCase(request.getMethod());
String name = request.getParameter("name");
String ageText = request.getParameter("age");
String batch = request.getParameter("batch");
String feesText = request.getParameter("fees");

if (isPost) {
    try {
        if (name == null || name.trim().isEmpty()) {
            message = "Please enter a name.";
        } else {
            int age = Integer.parseInt(ageText);
            double fees = Double.parseDouble(feesText);
            if (age < 10 || age > 70) {
                message = "Age must be between 10 and 70.";
            } else if (Double.isNaN(fees) || Double.isInfinite(fees) || fees < 0) {
                message = "Please enter a valid non-negative fee amount.";
            } else if (!("6 AM".equals(batch) || "7 AM".equals(batch) || "6 PM".equals(batch))) {
                message = "Please select a valid batch.";
            } else {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection con = null;
                PreparedStatement ps = null;
                try {
                    con = DriverManager.getConnection("jdbc:mysql://localhost:3306/college", "root", "root");
                    ps = con.prepareStatement("INSERT INTO registrations (name, age, batch, fees) VALUES (?, ?, ?, ?)");
                    ps.setString(1, name.trim());
                    ps.setInt(2, age);
                    ps.setString(3, batch);
                    ps.setDouble(4, fees);
                    ps.executeUpdate();
                    saved = true;
                } finally {
                    if (ps != null) try { ps.close(); } catch (SQLException ignored) { }
                    if (con != null) try { con.close(); } catch (SQLException ignored) { }
                }
            }
        }
    } catch (NumberFormatException e) {
        message = "Please enter a valid age and fee amount.";
    } catch (ClassNotFoundException e) {
        message = "MySQL JDBC driver is not configured in the project.";
    } catch (SQLException e) {
        application.log("Yoga enrollment database error", e);
        message = "Could not access the database. Check MySQL and the registrations table.";
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Yoga Registration Results</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 16px; color: #24322c; }
        h1 { color: #28634b; }
        .notice { padding: 12px 16px; border-radius: 6px; background: #f3f8f5; }
        .error { color: #a21d26; }
        .success { color: #17623b; }
        table { width: 100%; border-collapse: collapse; margin-top: 18px; }
        th, td { padding: 10px; border: 1px solid #d7e7dd; text-align: left; }
        th { background: #f3f8f5; }
        a { color: #28634b; }
    </style>
</head>
<body>
    <h1>Yoga Registration Results</h1>
    <% if (message != null) { %>
        <p class="notice error"><%= escapeHtml(message) %></p>
    <% } else if (saved) { %>
        <p class="notice success">Registration saved successfully.</p>
    <% } %>

    <p><a href="<%= request.getContextPath() %>/">Back to registration form</a></p>

    <h2>Registrations</h2>
    <%
    Connection con = null;
    Statement st = null;
    ResultSet rs = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection("jdbc:mysql://localhost:3306/college", "root", "root");
        st = con.createStatement();
        rs = st.executeQuery("SELECT id, name, age, batch, fees FROM registrations ORDER BY id");
        double total = 0;
    %>
    <table>
        <thead><tr><th>ID</th><th>Name</th><th>Age</th><th>Batch</th><th>Fees (Rs.)</th></tr></thead>
        <tbody>
        <% while (rs.next()) {
               double rowFees = rs.getDouble("fees");
               total += rowFees;
        %>
            <tr>
                <td><%= rs.getInt("id") %></td>
                <td><%= escapeHtml(rs.getString("name")) %></td>
                <td><%= rs.getInt("age") %></td>
                <td><%= escapeHtml(rs.getString("batch")) %></td>
                <td><%= rowFees %></td>
            </tr>
        <% } %>
        </tbody>
    </table>
    <p><strong>Total fees (Rs.): <%= total %></strong></p>
    <%
    } catch (Exception e) {
        application.log("Could not load yoga registrations", e);
    %>
        <p class="notice error">Could not load registrations. Check the MySQL JDBC driver, database, and registrations table.</p>
    <% } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignored) { }
        if (st != null) try { st.close(); } catch (SQLException ignored) { }
        if (con != null) try { con.close(); } catch (SQLException ignored) { }
    } %>
</body>
</html>
