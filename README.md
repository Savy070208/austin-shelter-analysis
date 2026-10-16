# Austin Animal Center Canine Adoption Analysis
**Author:** Savyansh Srivastava  
**Date:** October 2026

---

## 1. Ask Phase
- **Hypothetical Client:** Austin Animal Center Operations & Marketing Leadership
- **Business Task:** Analyze historical shelter intake and outcome data to identify the primary factors driving canine adoption decisions, in order to design targeted marketing strategies for at-risk and long-stay dogs while improving shelter adoption turnover.
- **Important Metrics:**
  - Length of Stay (LOS): Time from intake to adoption
  - Adoption Likelihood (%): Percentage of adopted dogs vs alternative shelter outcomes

---

## 2. Prepare Phase
- **Data Source:** City of Austin Open Data Portal (`data.austintexas.gov`). Data collected between August 2025 through October 7, 2026 (point-in-time recovery). 
- **Tables:**
  - `Austin_Animal_Center_Intakes.csv` (~18,374 rows)
  - `Austin_Animal_Center_Outcomes.csv` (~18,328 rows)
- **Primary Keys:** `id`
- **Join Key:** `animal_id`
- **Data Quality Assessment:**
    - Highly reliable government source
    - Multi-year records with day and month level timestamps
    - Consistently updated data
    - Complete records containing demographic attributes, medical details, etc
    - Public open-data under public domain license with no Personally Identifiable Information (PII) regarding owners or adopters
- **Initial Data Observations:**
  - `name`: Many missing values (strays); flag using new boolean `has_name`
  - `intake_health_condition`: Blanks need to be standardized to 'Unknown'
  - `secondary_color`: Empty values indicate solid-colored dogs
  - `date_of_birth`: Missing for many strays; use age brackets (Puppy, Adult, Senior) for age-based analysis

---

## 3. Process Phase
- **Initial Data Hygiene (Spreadsheet):**
  - Removed non-operational system export metadata column (`Timestamp` showing static batch export time)
  - Renamed `source date` to `intake_date` in the Intakes table for naming consistency across schemas
  - Filtered both tables strictly to canines (`type` in `'Dog'`, `'Puppy'`) to align with the canine-focused business task, deleted all alternative animal types
  - Ran Excel's remove duplicate function and identified 0 duplicate rows
  - Standardized missing and blank entries using consistent 'Unknown' and 'None' entries to preserve sample volume without null errors

- **Data Transformation and Validation (Spreadsheet)**
  - Created a boolean column `has_name` to flag canines with or without names
  - Validated `days_in_shelter` metric (`outcome_date - intake_date`); verified 0 negative durations across all records
  - Calculated exact ages in decimal years for `age_at_intake_years` and `age_at_outcome_years`; validated intake age anomalies
  - Categorized canines into standardized age brackets (`intake_age_bracket`, `outcome_age_bracket`):
    - Puppy: < 2.0 years
    - Adult: 2.0 - 7.99 years
    - Senior: ≥ 8.0 years

---

## 4. Analyze Phase
**Complete SQL scripts for this phase documented in [`scripts/canine_adoption_analysis.sql`](scripts/canine_adoption_analysis.sql)**

### 4.1 Adopted Outcome Status Categorization
To eliminate data noise across 26 outcome statuses and establish a clear baseline adoption rate, all canine records were consolidated into 5 outcome categories:
  - Adopted (53.50%)
  - Transfer Out (24.65%)
  - Return to Owner (16.16%)
  - Euthanasia (3.02%)
  - Other / Died in Care (2.67%)

#### Analytical Takeaways:
  - All relevant adoption variants (standard, altered, unaltered and off-site) combined to calculate true adoption rate
  - Relatively heavy reliance on partner shelters
  - Total positive outcomes amount to **94.31%** (6461 dogs)

### 4.2 Adoption Length of Stay (LOS) Metrics
Length of Stay (`days_in_shelter`) was evaluated across all 3,665 adopted canines for statistical exploration:
  - **Median Stay:** 26.0 days
  - **Average (Mean) Stay:** 59.6 days
  - **Range:** 0 to 1,641 days

To better scope the distribution, adoptions were segmented into tiers:
  - **0–7 days (Short-Term):** 19.45% (713 dogs)
  - **8–30 days (Average):** 35.25% (1,292 dogs)
  - **31–90 days (Extended Stay):** 27.34% (1,002 dogs)
  - **90+ days (Long-Term):** 17.95% (658 dogs)

#### Analytical Takeaways:
  - **Top-Heavy Data:** There is a large gap between the average LOS and median LOS suggesting that the upper 50th percentile of the data heavily skews the data
  - **Long-Stay Numbers:** Almost 18% of dogs are staying longer than 90 days, highlighting a clear target group for the marketing team

### 4.3 Demographic Factors for LOS (Adopted Dogs)
Aiming to identify which demographics influence adoption speed:

- **Naming Status:**
  - Most adopted dogs (89.8%) were named by the time they were adopted and no correlation can be found suggesting unnamed dogs are slower to be adopted

- **Canine Sex:**
  - There is an almost even split between adopted dogs being male and female suggesting no influence of a dog's gender on its LOS

- **Sterilization Status:**
  - **99%** of dogs were sterilized by the time of adoption due to mandatory shelter policy in Austin, Texas

- **Age Demographic:**
  - **Puppies (58% of adoptions)** had the shortest average LOS (39.5 days) with a 21 day median
  - **Adults (36.7% of adoptions)** had a high average LOS (86.0 days) with a 40 day median
  - **Seniors (4.88% of adoptions)** had the highest average LOS (102.5 days) but only a 23 day median suggesting skewed data

#### Analytical Takeaways:
  - **Uninfluential demographics:** Naming status, canine sex and sterilization status show no correlation with adoption speed
  - **Adult Dog Focus:** Adult dogs represent over a third of the adopted dogs and have double the average LOS than puppies, something for the marketing team to consider
  - **Senior Dog Numbers:** Most seniors find a home relatively quickly (23 day median) however a small subset of seniors heavily skew the average to 100+ days

### 4.4 Analysis of Non-Adoption Outcomes
Determine why canines exit through non-adoption outcomes and evaluate impact on kennel capacity, a total of 3186 dogs (46.5% of total shelter exits) explored

- **Unadopted Outcome Status Categorization:**
  - Transfer Out: **1689 dogs (53%)** with an average LOS of 25.8 days and median 5 days
  - Return to Owner: **1107 dogs (34.75%)** with an average LOS of 6.1 days and a median 2 days
  - Non-Live (Euthanasia/Death): **364 dogs (11.42%)** with an average LOS of 21.5 days and a median 6 days
  - Other: **26 dogs (0.82%)** with an average LOS of 19.8 days and a median 0 days

- **Unadopted Outcome Breakdown by Age Bracket:**
  - **Puppies (1,349 dogs):** **68.64%** transferred to partner rescues within a 5 day median stay (medical reasons)
  - **Adults (1,309 dogs):** Split between **Transfer Out (45.45%/43.1-day-average)** and **Return to Owner (43.47%/7-day-average)**
  - **Seniors (285 dogs):** Highest RTO rate (**49.82% RTO / 4.7-day average**), but highest mortality (**14.04% Non-Live**) due to terminal age-related medical conditions
  - **Unknown Age (243 dogs):** Highest non-live rate (**40.74%**), mostly comprised of DOA and severe health cases

- **Unadopted Outcome Breakdown by Dog Breed (Top 10):**
  - **American Pit Bull Terrier (686 dogs):** Dominates unadopted volume with highest non-live count (116 dogs) and a 28.5 day average LOS
  - **Labrador Retriever (372 dogs) & Chihuahua (275 dogs):** Main transfer targets, exiting to partner shelters in 4-6 days

#### Analytical Takeaways:
  - **RTOs don't limit shelter capacity:** RTOs account for a third of non adoptions and have a low LOS confirming no burden on shelter capacity
  - **Partner Transfers relieve puppy population:** Two-thirds of puppies exit via shelter transfer due to disease-mitigation, solving mass puppy overpopulation
  - **Adult Placement Challenge:** Unadopted adult dogs that are not quickly reclaimed endure long shelter stays before shelter transfer (43.1 day average LOS)
  - **Bully Breed Mortality and Delay:** American Pit Bull Terriers are the most unadopted breed and make-up one third of all shelter non-live outcomes, a potential primary focus

---

## 5. Share Phase
The exploratory findings from BigQuery were saved as CSV files and used to make data visuals in **Tableau Public**, focusing on efficiently showcasing analytical findings.

### 5.1 Overall Shelter Outcomes (Pie Chart):
- Sets the overall shelter baseline for all outcomes. **53.50%** adoption pathways versus **46.50%** non-adoption pathways (RTOs, transfers and mortality)

![Overall Shelter Outcomes](Visualisations/Visuals/Viz1%20Overall%20Outcomes.png)

### 5.2 Adopted Canine Length of Stay Distribution (Bar Chart):
- Highlights the capacity threshold. **45.29%** of adopted canines exceed the target 30-day average benchmark for adoption time (27.34% extended stays + 17.95% long-term stays)

![Adopted Canine Length of Stay Distribution](Visualisations/Visuals/Viz2%20Adopted%20LOS%20Tiers.png)

### 5.3 Adopted Canine Length of Stay by Age Bracket (Box-and-Whisker):
- Isolates the core driver of kennel stay duration: adult dogs experience a **40-day median stay** (nearly double the 21-day median for puppies)

![Adopted Canine Length of Stay by Age Bracket](Visualisations/Visuals/Viz3%20Adopted%20LOS%20by%20Age.png)

### 5.4 Top 10 Breeds by Non-Adoption Exits (Stacked Bar Chart):
- Reveals breed vulnerability: American Pit Bull Terriers dominate non-adoption exits (**686 dogs**) and account for **116 non-live outcomes** (1/3 of all shelter non-live outcomes)

![Top 10 Breeds by Non-Adoption Exits](Visualisations/Visuals/Viz4%20Unadopted%20Breed%20Breakdown.png)

### 5.5 Non-Adoption Exits by Age Group (100% Normalized Bar Chart):
- Dog outcomes when not adopted: puppies mostly move to partner rescues right away (**68.64%**), while seniors are usually lost pets returning to owners (**49.82%**). Adult dogs face the longest delay, waiting an average of **43.1 days** before being transferred out

![Non-Adoption Exits by Age Group](Visualisations/Visuals/Viz5%20Unadopted%20Outcomes%20by%20Age%20.png)

---


---

## 6. Act Phase

Based on the findings, a high-impact 3 step recommendation is compiled to tackle the business task given:

1. **Prioritize Adult-Canine Marketing & Adoption Programs:**
   - *Rationale:* Adult dogs represent over a third of adoptions and remain in kennels twice as long as puppies
   - *Action:* Shift digital marketing, social spotlight features, and weekend adoption events toward adult canines. Implement structured "foster-to-adopt" trials for dogs exceeding 30 days to free up physical kennel capacity and motivate potential adopters with a trial

2. **Establish Dedicated Bully Breed Placement Motions:**
   - *Rationale:* American Pit Bull Terriers represent the single largest non-adoption volume (686 dogs) and account for nearly one-third of all shelter non-live outcomes (116 dogs).
   - *Action:* Form  partnerships with bully-breed-specific rescues and offer subsidized behavioral training support for potential adopters to reduce non-live outcomes

3. **Accelerate Senior Canine Reclaims via Community Engagement:**
   - *Rationale:* Nearly half of unadopted senior dogs are returning to existing owners, achieving a low median length of stay (1 day).
   - *Action:* Expand community microchip scanning access and designate staff to manage lost-and-found efforts. For owners, initiate an intake diversion consultation providing veterinary care and short-term fostering

---

## 7. Tools, Data Sources and Credits
- **Data Source:** City of Austin Open Data Portal (`data.austintexas.gov`). Intakes and Outcomes datasets published under public domain
- **Methodology:** Google Data Analysis 6-phase process(Ask, Prepare, Process, Analyze, Share, Act)
- **Tools Used:**
  - **Data Hygiene & Transformation:** Microsoft Excel
  - **Statistical Data Querying:** Google Cloud BigQuery (Standard SQL)
  - **Data Visualization & Dashboard Design:** Tableau Public
  - **Collaborative Content Drafting & Technical Consultation:** Gemini (Google AI)
