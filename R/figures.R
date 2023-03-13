
# load ----
library(tidyverse)
library(tidytable)
library(vroom)
library(here)
library(purrr)
library(rsample)
library(data.table)
library(scico)
library(extrafont)
library(cowplot)
library(egg)
library(gg.layers)
# remotes::install_version("Rttf2pt1", version = "1.3.8")
# extrafont::font_import()
loadfonts(device="win")   

# if you get a lot of messages like 'C:\Windows\Fonts\ALGER.TTF : No FontName. Skipping.'
# then load this package and then run font_import
# remotes::install_version("Rttf2pt1", version = "1.3.8")

# add fonts to all text (last line)
ggplot2::theme_set(
  ggplot2::theme_light() +
    ggplot2::theme(
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      # axis.ticks.length = grid::unit(base_ / 2.2, "pt"),
      strip.background = ggplot2::element_rect(fill = NA, colour = NA),
      strip.text.x = element_text(colour = "black"),
      strip.text.y = element_text(colour = "black"),
      panel.border = element_rect(fill = NA),
      legend.key.size = grid::unit(0.9, "lines"),
      legend.key = ggplot2::element_rect(colour = NA, fill = NA),
      legend.background = ggplot2::element_rect(colour = NA, fill = NA),
      text = element_text(family = "Times New Roman")
    )
)

# pull in output ----

spec <- vroom::vroom(here::here('data', 'species_code_name.csv')) # species_code and common names

r_t <- vroom::vroom(here::here('data', 'reader_tester.csv'))

specimen <- vroom::vroom(here::here('data', 'specimen_ai.csv')) %>% 
  tidytable::mutate(region = 'ai') %>% 
  tidytable::bind_rows(vroom::vroom(here::here('data', 'specimen_bs.csv')) %>% 
                         tidytable::mutate(region = 'bs')) %>% 
  tidytable::bind_rows(vroom::vroom(here::here('data', 'specimen_goa.csv')) %>% 
                         tidytable::mutate(region = 'goa'))

err_iss <- vroom::vroom(here::here('output', 'afsc_iss_err.csv'))

surv_labs <- c("Aleutian Islands", "Bering Sea Shelf", "Gulf of Alaska")
names(surv_labs) <- c("ai", "bs", "goa")

# add specimen info to iss results

specimen %>% 
  tidytable::drop_na() %>% 
  tidytable::summarise(nhls = length(unique(hauljoin)),
                       nss = length(age), .by = c(year, species_code, region, sex)) %>% 
  tidytable::filter(sex != 3) %>% 
  tidytable::mutate(comp_type = case_when (sex == 1 ~ 'male',
                                           sex == 2 ~ 'female')) %>% 
  tidytable::select(-sex) %>% 
  tidytable::bind_rows(specimen %>% 
                         tidytable::drop_na() %>% 
                         tidytable::summarise(nhls = length(unique(hauljoin)),
                                              nss = length(age), .by = c(year, species_code, region, sex)) %>% 
                         tidytable::summarise(nhls = sum(nhls),
                                              nss = sum(nss), .by = c(year, species_code, region)) %>% 
                         tidytable::mutate(comp_type = 'total')) -> samp_dat

species = unique(err_iss$species_code)

r_t %>% 
  tidytable::filter(species_code %in% species,
                    Region %in% c('AI', 'BS', 'BS/AI', 'BS_GOA', 'BSAI', 'BSGOA', 'GOA')) %>% 
  dplyr::rename_all(tolower) %>% 
  tidytable::select(species_code, read_age, test_age) %>% 
  tidytable::drop_na() %>% 
  tidytable::filter(read_age > 0) %>% 
  tidytable::mutate(diff = abs(read_age - test_age) / read_age) %>% 
  tidytable::summarise(ape1 = sum(diff),
                       R = length(diff), .by = c(species_code, read_age)) %>% 
  tidytable::summarise(ape2 = sum(ape1 / R),
                       N = sum(R), .by = c(species_code)) %>% 
  tidytable::mutate(ape = 100 * ape2 / N) %>% 
  tidytable::select(species_code, ape) -> ape

specimen %>% 
  tidytable::drop_na() %>% 
  tidytable::summarise(sd_l1 = sd(length), .by = c(species_code, sex, region, age)) %>%
  tidytable::drop_na() %>% 
  tidytable::summarise(sd_l = mean(sd_l1), .by = c(species_code, sex, region)) %>% 
  tidytable::filter(sex != 3) %>% 
  tidytable::mutate(comp_type = case_when (sex == 1 ~ 'male',
                                           sex == 2 ~ 'female')) %>% 
  tidytable::select(-sex) %>% 
  tidytable::bind_rows(specimen %>% 
                         tidytable::drop_na() %>% 
                         tidytable::summarise(sd_l1 = sd(length), .by = c(species_code, region, age)) %>%
                         tidytable::drop_na() %>% 
                         tidytable::summarise(sd_l = mean(sd_l1), .by = c(species_code, region)) %>% 
                         tidytable::mutate(comp_type = 'total')) -> sd_l

err_iss %>% 
  tidytable::left_join(samp_dat) %>% 
  tidytable::left_join(ape) %>% 
  tidytable::left_join(sd_l) %>% 
  vroom::vroom_write(.,
                     here::here('output', 'afsc_iss_err_full.csv'),
                     delim = ',') -> plot_dat
  

# plot age iss with added error ----

plot_dat %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, region) %>% 
  tidytable::left_join(spec) %>%
  tidytable::pivot_longer(cols = c(ae, ae_al, al, base)) %>% 
  tidytable::mutate(err_src = case_when(name == 'ae' ~ 'AE',
                                        name == 'al' ~ 'AL',
                                        name == 'ae_al' ~ 'AE & AL',
                                        name == 'base' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Bering Sea Shelf"),
                    err_src = factor(err_src)) -> plot_dat_iss

plot_dat_iss %>% 
  ggplot(., aes(x = factor(err_src, level = c('Base', 'AE', 'AL', 'AE & AL')), 
                y = value, 
                fill = comp_type)) +
  geom_boxplot2(width.errorbar = 0) +
  facet_grid(surv_labs ~ species_name, 
             # scales = "free",
             labeller = label_wrap_gen(10)) +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = -45, hjust = 0),
        text = element_text(size = 11)) +
  xlab("Uncertainty scenario") +
  ylab("Age composition input sample size") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Composition type") -> iss_plot

ggsave(here::here("figs", "iss_plot.png"),
       iss_plot,
       device = "png",
       width = 6,
       height = 6)


# plot prop of base age iss with added error ----

plot_dat %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, region) %>% 
  tidytable::left_join(spec) %>%
  tidytable::mutate(prop_ae = ae / base,
                    prop_al = al / base,
                    prop_ae_al = ae_al / base) %>% 
  tidytable::pivot_longer(cols = c(prop_ae, prop_ae_al, prop_al)) %>% 
  tidytable::mutate(err_src = case_when(name == 'prop_ae' ~ 'AE',
                                        name == 'prop_al' ~ 'AL',
                                        name == 'prop_ae_al' ~ 'AE & AL'),
  surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                        region == 'ai' ~ "Aleutian Islands",
                        region == 'bs' ~ "Bering Sea Shelf"),
  err_src = factor(err_src)) -> plot_dat_prop_iss

plot_dat_prop_iss %>% 
  tidytable::drop_na() %>% 
  tidytable::filter(species_type != "other") %>% 
  tidytable::summarise(mean_p = mean(value), .by = c(species_name, species_type, comp_type, err_src, region)) %>%
  ggplot(.,aes(x = species_type, y = mean_p, fill = as.factor(species_type))) +
  geom_boxplot2(width.errorbar = 0) +
  facet_grid(comp_type ~ factor(err_src, level = c('AE', 'AL', 'AE & AL'))) +
  ylab("Proportion of base age composition input sample size") +
  xlab("Species type") +
  scale_fill_scico_d(palette = 'roma',
                     name = "Species type") + 
  theme(text = element_text(size = 14),
        legend.position = "none") -> prop_iss_plot

ggsave(here::here("figs", "prop_iss_plot.png"),
       prop_iss_plot,
       device = "png",
       width = 6,
       height = 6)

# plot iss and nss per haul with added error ----

surv_labs <- c("Aleutian Isalnds", "Bering Sea Shelf", "Gulf of Alaska")
names(surv_labs) <- c("ai", "bs", "goa")

plot_dat %>% 
  select(year, species_code, comp_type, ae, ae_al, al, base, nhls, nss, region) %>% 
  tidytable::left_join(spec) %>% 
  tidytable::mutate(ae_hl = ae / nhls,
                    al_hl = al / nhls,
                    ae_al_hl = ae_al / nhls,
                    base_hl = base / nhls,
                    n_hl = nss/ nhls) %>% 
  tidytable::pivot_longer(cols = c(ae_hl, al_hl, ae_al_hl, base_hl)) %>% 
  tidytable::mutate(err_src = case_when(name == 'ae_hl' ~ 'AE',
                                        name == 'al_hl' ~ 'AL',
                                        name == 'ae_al_hl' ~ 'AE & AL',
                                        name == 'base_hl' ~ 'Base'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Bering Sea Shelf"),
                    err_src = factor(err_src),
                    surv_labs = factor(surv_labs)) %>% 
  tidytable::filter(species_type != 'other') -> hls_dat

hls_dat %>% 
  ggplot(.,aes(x = n_hl, y = value, color = as.factor(species_type))) +
  geom_point() +
  stat_ellipse(aes(fill = species_type, 
                   color = species_type), 
               alpha = 0.25, 
               level = 0.95,
               type = "norm",
               geom = "polygon") +
  scale_shape_manual(values=seq(0,14)) +
  facet_grid( ~ factor(err_src, level = c('Base', 'AE', 'AL', 'AE & AL')),
             labeller = labeller(region = surv_labs)) +
  geom_abline(slope = 1, intercept = 0, colour = "black", xintercept = 1) +
  geom_abline(slope = 0, intercept = 1, colour = "black") +
  xlab("Number of age samples per sampled haul") +
  ylab("Age composition input sample size per sampled haul") +
  labs(pch = "Stock") +
  scale_color_scico_d(palette = 'roma',
                      name = "Species type") + 
  scale_fill_scico_d(palette = 'roma',
                      name = "Species type") + 
  theme(text = element_text(size = 14),
        strip.text = element_blank(),
        legend.position = "none",
        axis.title.y = element_blank()) -> iss_nss_hls


hls_dat %>% 
  tidytable::drop_na() %>% 
  tidytable::summarise(mean_hl = mean(value),
                       lci_hl = quantile(value, probs = 0.025),
                       uci_hl = quantile(value, probs = 0.975), .by = c(species_type, err_src)) %>% 
  ggplot(.,aes(x = species_type, y = mean_hl, fill = as.factor(species_type))) +
  geom_bar(stat = "identity") +
  facet_grid( ~ factor(err_src, level = c('Base', 'AE', 'AL', 'AE & AL'))) +
  xlab("Number of age samples per sampled haul") +
  ylab("Age composition input sample size per sampled haul") +
  labs(pch = "Stock") +
  scale_color_scico_d(palette = 'roma',
                      name = "Species type") + 
  scale_fill_scico_d(palette = 'roma',
                     name = "Species type") + 
  theme(text = element_text(size = 14),
        axis.title.x = element_blank(),
        strip.text.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "bottom") +
  geom_errorbar(aes(x = species_type, ymin = lci_hl, ymax = uci_hl), width = 0) -> iss_hls


hls_iss_nss <- ggarrange(iss_nss_hls,
                         iss_hls,
                         ncol= 1,
                         left = "Age composition input sample size per sampled haul")

ggsave(here::here("figs", "hls_iss_nss.png"),
       hls_iss_nss,
       device = "png",
       width = 7,
       height = 6)




# plot relationship with ape and sd_l ----



plot_dat %>% 
  tidytable::left_join(spec) %>%
  tidytable::mutate(prop_ae = ae / base,
                    prop_al = al / base,
                    prop_ae_al = ae_al / base) %>% 
  tidytable::pivot_longer(cols = c(prop_ae, prop_ae_al, prop_al)) %>% 
  tidytable::mutate(err_src = case_when(name == 'prop_ae' ~ 'AE',
                                        name == 'prop_al' ~ 'AL',
                                        name == 'prop_ae_al' ~ 'AE & AL'),
                    surv_labs = case_when(region == 'goa' ~ "Gulf of Alaska",
                                          region == 'ai' ~ "Aleutian Islands",
                                          region == 'bs' ~ "Bering Sea Shelf"),
                    err_src = factor(err_src)) -> plot_dat_ape



plot_dat_ape %>% 
  tidytable::filter(err_src == 'AL') %>% 
  ggplot(.,aes(x = sd_l, y = value, color = as.factor(species_type), fill = as.factor(species_name))) +
  geom_boxplot2(width.errorbar = 0) +
  geom_point() +
  stat_ellipse(aes(fill = species_type, 
                   color = species_type), 
               alpha = 0.25, 
               level = 0.95,
               type = "norm",
               geom = "polygon") +
  scale_shape_manual(values=seq(0,14)) +
  facet_grid( ~ factor(err_src, level = c('Base', 'AE', 'AL', 'AE & AL')),
              labeller = labeller(region = surv_labs)) +
  geom_abline(slope = 1, intercept = 0, colour = "black", xintercept = 1) +
  geom_abline(slope = 0, intercept = 1, colour = "black") +
  xlab("Number of age samples per sampled haul") +
  ylab("Age composition input sample size per sampled haul") +
  labs(pch = "Stock") +
  # geom_smooth(method = 'lm', se = T) +
  scale_color_scico_d(palette = 'roma',
                      name = "Species type") + 
  scale_fill_scico_d(palette = 'roma',
                     name = "Species type") + 
  theme(text = element_text(size = 14)) 














