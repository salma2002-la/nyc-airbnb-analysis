 🏠 New York City Airbnb Investment Analysis (End-to-End Project)

 📌 Business Scenario & Objective
A real-estate investment firm is looking to expand its short-term rental portfolio in New York City. As a Junior Data Analyst, my objective is to analyze historic Airbnb data to guide investment strategy—identifying optimal boroughs, property types, and key pricing drivers to maximize return on investment (ROI).



 🛠️ Tools & Tech Stack
* **Python (Google Colab / Pandas):** Data cleaning, missing value imputation, Feature Engineering (Estimated Revenue & Keyword Extraction), and EDA.
* **MySQL:** Database schema design, table normalization (Relational Modeling), and analytical SQL queries (CTEs, Window Functions, JOINs).
* **Power BI:** Interactive dashboard design, KPI tracking, and spatial visualization.
* **GitHub:** Documentation and repository management.



 ❓ Key Business Questions
**1. Pricing & Yield:** What is the average price and potential revenue across NYC boroughs?
 **2. Demand & Activity:** Which neighborhoods show the highest guest demand (based on review activity and availability)?
 **3. Quality & Hidden Gems:** Are there high-rated, high-demand neighborhoods with moderate property prices?
 **4. Property Types:** Which room types (Entire home vs. Private room) generate the highest estimated revenue?
 **5. Competition & Host Profile:** Is the market dominated by single hosts or multi-listing real estate investors?
 **6. Marketing Impact:** Do specific listing title keywords (e.g., "Luxury", "Cozy", "Modern") correlate with higher prices?



 🔄 Project Pipeline
1. **Ask Phase:** Defined business problems and core investment metrics.
2. **Data Cleaning & EDA (Python):** Cleaned `AB_NYC_2019.csv` in Google Colab, handled missing values, engineered `estimated_revenue`, and extracted title tags.
3. **Relational Database & SQL Analysis (MySQL):** Split clean data into relational tables, created indices, and ran analytical business queries.
4. **Data Visualization (Power BI):** Modeled data connections and designed executive dashboards for stakeholders.
5. **Insights & Actionable Recommendations:** Delivered clear data-driven takeaways on where to purchase properties.

---

 📁 Repository Structure
```text
Airbnb_NYC_Project/
├── data/           # Raw and Cleaned CSV files
├── notebooks/      # Python / Google Colab Notebooks (.ipynb)
├── sql/            # MySQL relational scripts and analytical queries (.sql)
├── dashboard/      # Power BI (.pbix) file and screenshots
└── docs/           # Ask Phase & Business Documentation